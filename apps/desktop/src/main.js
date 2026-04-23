const { app, BrowserWindow, Menu, Tray, shell, ipcMain, nativeTheme } = require('electron');
const { autoUpdater } = require('electron-updater');
const Store = require('electron-store');
const path  = require('path');
const isDev = process.env.NODE_ENV === 'development' || !app.isPackaged;

// ─── Persistent store ─────────────────────────────────────────────────────────
const store = new Store({
  schema: {
    windowBounds: { type: 'object', default: { width: 1280, height: 820 } },
    isMaximized:  { type: 'boolean', default: false },
  }
});

let mainWindow = null;
let tray        = null;

// ─── Window factory ───────────────────────────────────────────────────────────
function createWindow() {
  const { width, height } = store.get('windowBounds');

  mainWindow = new BrowserWindow({
    width,
    height,
    minWidth:  960,
    minHeight: 680,
    title:     'FLUJO Finance OS',
    titleBarStyle: process.platform === 'darwin' ? 'hiddenInset' : 'default',
    backgroundColor: '#0A0F1A',
    show: false, // show after ready-to-show
    webPreferences: {
      preload:            path.join(__dirname, 'preload.js'),
      contextIsolation:   true,
      nodeIntegration:    false,
      webSecurity:        true,
    },
    icon: path.join(__dirname, '../assets/icon.png'),
  });

  // Restore maximized state
  if (store.get('isMaximized')) mainWindow.maximize();

  // Load the Next.js app
  const url = isDev
    ? 'http://localhost:3000'
    : `file://${path.join(__dirname, '../../web/out/index.html')}`;

  mainWindow.loadURL(url);

  // Show once ready to avoid flash
  mainWindow.once('ready-to-show', () => mainWindow.show());

  // Save window state on resize / move
  const saveState = () => {
    if (!mainWindow.isMaximized() && !mainWindow.isMinimized()) {
      store.set('windowBounds', mainWindow.getBounds());
    }
    store.set('isMaximized', mainWindow.isMaximized());
  };
  mainWindow.on('resize',    saveState);
  mainWindow.on('move',      saveState);
  mainWindow.on('maximize',  saveState);
  mainWindow.on('unmaximize',saveState);

  // Open external links in default browser
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    if (url.startsWith('http')) shell.openExternal(url);
    return { action: 'deny' };
  });

  // DevTools in dev mode
  if (isDev) mainWindow.webContents.openDevTools({ mode: 'detach' });

  mainWindow.on('closed', () => { mainWindow = null; });
}

// ─── System tray ─────────────────────────────────────────────────────────────
function createTray() {
  const iconPath = path.join(__dirname, '../assets/tray-icon.png');
  tray = new Tray(iconPath);

  const contextMenu = Menu.buildFromTemplate([
    { label: 'Abrir FLUJO', click: () => {
      if (mainWindow) mainWindow.show();
      else createWindow();
    }},
    { type: 'separator' },
    { label: 'Dashboard', click: () => {
      if (mainWindow) { mainWindow.show(); mainWindow.webContents.loadURL(isDev ? 'http://localhost:3000/app/dashboard' : ''); }
    }},
    { label: 'Nuevo movimiento', click: () => {
      if (mainWindow) mainWindow.webContents.executeJavaScript('window.__flujoAddTx && window.__flujoAddTx()');
    }},
    { type: 'separator' },
    { label: 'Verificar actualizaciones', click: () => autoUpdater.checkForUpdatesAndNotify() },
    { type: 'separator' },
    { label: 'Salir', role: 'quit' },
  ]);

  tray.setToolTip('FLUJO Finance OS');
  tray.setContextMenu(contextMenu);
  tray.on('double-click', () => {
    if (mainWindow) mainWindow.show();
    else createWindow();
  });
}

// ─── Application menu ─────────────────────────────────────────────────────────
function buildMenu() {
  const template = [
    ...(process.platform === 'darwin' ? [{
      label: app.name,
      submenu: [
        { role: 'about' },
        { type: 'separator' },
        { role: 'services' },
        { type: 'separator' },
        { role: 'hide' }, { role: 'hideOthers' }, { role: 'unhide' },
        { type: 'separator' },
        { role: 'quit' },
      ],
    }] : []),
    {
      label: 'Archivo',
      submenu: [
        { label: 'Nuevo movimiento', accelerator: 'CmdOrCtrl+N',
          click: () => mainWindow?.webContents.executeJavaScript('window.__flujoAddTx && window.__flujoAddTx()') },
        { type: 'separator' },
        { label: 'Exportar Excel', accelerator: 'CmdOrCtrl+E', click: () => {} },
        { type: 'separator' },
        process.platform === 'darwin' ? { role: 'close' } : { role: 'quit', label: 'Salir' },
      ],
    },
    {
      label: 'Vista',
      submenu: [
        { role: 'reload' }, { role: 'forceReload' },
        { type: 'separator' },
        { role: 'resetZoom' }, { role: 'zoomIn' }, { role: 'zoomOut' },
        { type: 'separator' },
        { role: 'togglefullscreen' },
        ...(isDev ? [{ type: 'separator' }, { role: 'toggleDevTools' }] : []),
      ],
    },
    {
      label: 'Ventana',
      submenu: [
        { role: 'minimize' }, { role: 'zoom' },
        ...(process.platform === 'darwin' ? [{ type: 'separator' }, { role: 'front' }] : []),
      ],
    },
    {
      label: 'Ayuda',
      submenu: [
        { label: 'Documentación', click: () => shell.openExternal('https://flujo.app/docs') },
        { label: 'Reportar un problema', click: () => shell.openExternal('https://flujo.app/support') },
        { type: 'separator' },
        { label: 'Verificar actualizaciones', click: () => autoUpdater.checkForUpdatesAndNotify() },
      ],
    },
  ];

  Menu.setApplicationMenu(Menu.buildFromTemplate(template));
}

// ─── IPC handlers ─────────────────────────────────────────────────────────────
ipcMain.handle('get-version',    () => app.getVersion());
ipcMain.handle('get-platform',   () => process.platform);
ipcMain.handle('minimize-window',() => mainWindow?.minimize());
ipcMain.handle('maximize-window',() => mainWindow?.isMaximized() ? mainWindow.unmaximize() : mainWindow?.maximize());
ipcMain.handle('close-window',   () => mainWindow?.close());
ipcMain.handle('open-external',  (_, url) => shell.openExternal(url));

// ─── Auto-updater ─────────────────────────────────────────────────────────────
function setupAutoUpdater() {
  autoUpdater.autoDownload = false;
  autoUpdater.on('update-available', () => {
    mainWindow?.webContents.send('update-available');
  });
  autoUpdater.on('update-downloaded', () => {
    mainWindow?.webContents.send('update-downloaded');
  });
  ipcMain.handle('install-update', () => autoUpdater.quitAndInstall());
  if (!isDev) autoUpdater.checkForUpdatesAndNotify();
}

// ─── App lifecycle ────────────────────────────────────────────────────────────
app.whenReady().then(() => {
  nativeTheme.themeSource = 'dark';

  createWindow();
  buildMenu();
  createTray();
  setupAutoUpdater();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

// Prevent multiple instances
const gotLock = app.requestSingleInstanceLock();
if (!gotLock) {
  app.quit();
} else {
  app.on('second-instance', () => {
    if (mainWindow) {
      if (mainWindow.isMinimized()) mainWindow.restore();
      mainWindow.focus();
    }
  });
}
