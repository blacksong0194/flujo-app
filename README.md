# FLUJO Finance OS

> Sistema completo de gestión de finanzas personales — Web · Android · iOS · Windows

![FLUJO Dashboard](./docs/dashboard-preview.png)

---

## Stack tecnológico

| Capa | Tecnología |
|------|-----------|
| Web App | Next.js 14 + React + TypeScript |
| Mobile  | Flutter 3 (Android + iOS) |
| Desktop | Electron 32 (Windows / Mac / Linux) |
| Backend | Supabase (PostgreSQL + Auth + Realtime) |
| Estado  | Zustand (web) · Riverpod (mobile) |
| Estilos | Tailwind CSS |
| Monorepo| Turborepo |

---

## Estructura del proyecto

```
flujo/
├── apps/
│   ├── web/          → Next.js 14 (PWA)
│   ├── mobile/       → Flutter
│   └── desktop/      → Electron
├── supabase/
│   └── migrations/   → SQL schema completo
├── turbo.json
└── package.json
```

---

## 🚀 Puesta en marcha rápida

### 1. Configurar Supabase

1. Ir a [supabase.com](https://supabase.com) → **New project**
2. Copiar la URL y la Anon Key del proyecto
3. Abrir **SQL Editor** → pegar y ejecutar el contenido de `supabase/migrations/001_init.sql`
4. En **Authentication → Providers** → activar **Google** (opcional)

### 2. Web App (Next.js)

```bash
cd apps/web

# Configurar variables de entorno
cp .env.example .env.local
# Editar .env.local con tus credenciales de Supabase

# Instalar dependencias
npm install

# Ejecutar en desarrollo
npm run dev
# → http://localhost:3000

# Build de producción
npm run build
npm run start
```

### 3. Deploy en Vercel (recomendado — gratis)

```bash
# Instalar Vercel CLI
npm i -g vercel

# Desde apps/web/
vercel

# Configurar en el dashboard de Vercel:
# Settings → Environment Variables → agregar:
#   NEXT_PUBLIC_SUPABASE_URL
#   NEXT_PUBLIC_SUPABASE_ANON_KEY
```

### 4. App Mobile (Flutter)

**Requisitos:** Flutter SDK ≥ 3.0, Android Studio o Xcode

```bash
cd apps/mobile

# Instalar dependencias
flutter pub get

# Configurar credenciales de Supabase en lib/main.dart:
#   const supabaseUrl = 'https://TU_PROYECTO.supabase.co';
#   const supabaseAnonKey = 'TU_ANON_KEY';

# Ejecutar en dispositivo / emulador
flutter run

# Build APK para Android
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk

# Build para iOS (requiere Mac + Xcode)
flutter build ios --release
```

### 5. App Desktop (Electron)

```bash
cd apps/desktop

npm install

# Desarrollo (requiere la web app corriendo en :3000)
npm run dev

# Build Windows (.exe instalador)
npm run build -- --win

# Build Mac (.dmg)
npm run build -- --mac

# Build Linux (.AppImage)
npm run build -- --linux

# Los instaladores quedan en apps/desktop/dist/
```

---

## 📱 Primera vez — Configurar categorías

Después de crear tu cuenta, ve a **Ajustes → Categorías → Cargar categorías predeterminadas**

Esto creará las 21 categorías del Excel original:
- **5 de ingreso**: ajuste, salario, asesoría, arriendo, inversión
- **16 de egreso**: servicios, alimentación, compras, pólizas, renta, salud, impuestos, membresías, reparaciones, esparcimiento, educación, transporte, despensas, vestuarios, medicinas

---

## 🗄️ Base de datos

### Tablas principales

| Tabla | Descripción |
|-------|-------------|
| `profiles` | Perfil del usuario (extiende `auth.users`) |
| `accounts` | Cuentas / almacenes (bancos, efectivo, deudas) |
| `categories` | Categorías de movimientos (ingresos/egresos) |
| `transactions` | Todos los movimientos financieros |
| `budgets` | Límites de gasto por categoría |
| `goals` | Metas de ahorro con seguimiento |
| `notifications` | Alertas del sistema |

### Seguridad (RLS)

Todas las tablas tienen **Row Level Security** activado. Cada usuario solo puede ver y modificar sus propios datos. La política `"Users own data"` se aplica a todas las tablas.

### Vistas útiles

```sql
-- Resumen mensual por usuario
SELECT * FROM v_monthly_summary WHERE user_id = auth.uid();

-- Balances de cuentas con conteo de transacciones
SELECT * FROM v_account_balances WHERE user_id = auth.uid();
```

---

## 🔐 Variables de entorno

```bash
# apps/web/.env.local
NEXT_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGc...
```

---

## 📦 Módulos de la app

| Módulo | Ruta web | Descripción |
|--------|----------|-------------|
| Dashboard | `/app/dashboard` | KPIs, tendencias, alertas, movimientos recientes |
| Cuentas | `/app/accounts` | Bancos, efectivo, inversiones, deudas |
| Movimientos | `/app/transactions` | Registro completo con filtros y búsqueda |
| Presupuesto | `/app/budgets` | Límites mensuales por categoría con progress bars |
| Metas | `/app/goals` | Objetivos de ahorro con ETA y tracking |
| Reportes | `/app/reports` | Gráficas, análisis, indicadores financieros |
| Ajustes | `/app/settings` | Perfil, categorías, exportación, sincronización |

---

## 💰 Costos de infraestructura

| Servicio | Plan | Costo |
|----------|------|-------|
| Supabase | Free (hasta 50k filas, 2 proyectos) | **$0/mes** |
| Vercel | Hobby (deploy Next.js) | **$0/mes** |
| Google Play | Pago único | **$25** |
| Apple App Store | Anual | **$99/año** |

**Total para empezar: $0/mes**

---

## 🛠️ Desarrollo

```bash
# Desde la raíz del monorepo
npm install

# Correr todos los proyectos a la vez
npm run dev

# Solo web
npm run web
```

---

## 📄 Licencia

MIT © 2025 FLUJO Finance OS
