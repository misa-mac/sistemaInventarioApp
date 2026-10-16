# Sistema de Inventario ITBM (Monorepo)

Monorepo integral para el control de inventarios, auditorías y activos con códigos QR del ITBM.

---

## 📁 Estructura del Proyecto

```text
sistemaInventarioApp/
├── backend/            # API REST (Node.js, Express, Sequelize, PostgreSQL)
├── frontend-web/       # Panel Administrativo Web (React 18, Vite, Tailwind CSS)
├── mobile/             # Aplicación Móvil (Flutter, Provider, Hive, QR Scanner)
└── docs/               # Documentación general y referencias de diseño
```

---

## 🚀 Guía de Inicio Rápido

### 1. Backend (`/backend`)
API RESTful construida con Node.js, Express y PostgreSQL.

```bash
cd backend
npm install
# Configura tu archivo .env (puedes basarte en .env.example)
npm start # o npm run dev
```

* **Puerto por defecto:** `3000`
* **Base de datos:** PostgreSQL (`inventario_db`)

---

### 2. Panel Web (`/frontend-web`)
Panel de control reactivo construido con React y Vite.

```bash
cd frontend-web
npm install
npm run dev
```

* **URL de desarrollo:** `http://localhost:5173`

---

### 3. Aplicación Móvil (`/mobile`)
App móvil para escaneo QR y auditorías físicas desarrollada en Flutter.

```bash
cd mobile
flutter pub get
flutter run
```

---

## 📄 Documentación Adicional
En la carpeta [docs/](file:///c:/Users/PC/Desktop/app/sistemaInventarioApp/docs/) encontrarás:
* `resumen_proyecto.txt`: Resumen arquitectónico de los módulos y funcionalidades.
* `design_reference/`: Mockups y guías de estilos de la interfaz.
