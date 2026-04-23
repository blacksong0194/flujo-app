const { contextBridge, ipcRenderer } = require('electron');

// Expose a safe, narrow API to the renderer (Next.js app)
contextBridge.exposeInMainWorld('electronAPI', {
  // App info
  getVersion:  () => ipcRenderer.invoke('get-version'),
  getPlatform: () => ipcRenderer.invoke('get-platform'),

  // Window controls
  minimize: () => ipcRenderer.invoke('minimize-window'),
  maximize: () => ipcRenderer.invoke('maximize-window'),
  close:    () => ipcRenderer.invoke('close-window'),

  // External links
  openExternal: (url) => ipcRenderer.invoke('open-external', url),

  // Auto-update
  installUpdate: () => ipcRenderer.invoke('install-update'),
  onUpdateAvailable: (cb) => ipcRenderer.on('update-available', cb),
  onUpdateDownloaded: (cb) => ipcRenderer.on('update-downloaded', cb),

  // Check if running inside Electron
  isElectron: true,
});
