# Zen - Gestor de Productividad Personal

<p align="center">
  <strong>Tu compañero digital para una vida equilibrada y productiva</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.10+-0175C2?logo=dart" alt="Dart">
  <img src="https://img.shields.io/badge/Node.js-18+-339933?logo=node.js" alt="Node.js">
  <img src="https://img.shields.io/badge/MySQL-8.0+-4479A1?logo=mysql&logoColor=white" alt="MySQL">
  <img src="https://img.shields.io/badge/Licencia-MIT-green" alt="Licencia">
</p>

---

## Índice

1. [Descripción del Proyecto](#descripción-del-proyecto)
2. [Características Principales](#características-principales)
3. [Arquitectura y Estructura del Proyecto](#arquitectura-y-estructura-del-proyecto)
4. [Requisitos Previos](#requisitos-previos)
5. [Instalación y Ejecución](#instalación-y-ejecución)
6. [Configuración de Variables de Entorno](#configuración-de-variables-de-entorno)
7. [API REST - Endpoints](#api-rest---endpoints)
8. [Casos de Uso](#casos-de-uso)
9. [Requisitos Funcionales](#requisitos-funcionales)
10. [Requisitos No Funcionales](#requisitos-no-funcionales)
11. [Esquema Entidad-Relación](#esquema-entidad-relación)
12. [Normalización de la Base de Datos](#normalización-de-la-base-de-datos)
13. [Diagrama de Gantt](#diagrama-de-gantt)
14. [Análisis DAFO](#análisis-dafo)
15. [Stack Tecnológico](#stack-tecnológico)
16. [Licencia](#licencia)
17. [Autor](#autor)

---

## Descripción del Proyecto

**Zen** es una aplicación multiplataforma de gestión de productividad personal desarrollada con **Flutter** (frontend) y **Node.js + Express** (backend), respaldada por una base de datos **MySQL**. Permite a los usuarios organizar su día a día a través de tareas, proyectos, recordatorios, rutinas y objetivos personales, todo con una interfaz moderna e intuitiva.

La aplicación está diseñada para ejecutarse en **Android, iOS, Web, Windows, macOS y Linux**, aprovechando la naturaleza multiplataforma de Flutter.

---

## Características Principales

| Módulo | Descripción |
|--------|-------------|
| 📋 **Gestión de Tareas** | Crea, edita, asigna prioridades (baja, media, alta, urgente) y realiza seguimiento de estado (pendiente, en progreso, completada, cancelada). Soporta etiquetas, horas estimadas/reales y adjuntos. |
| 📁 **Proyectos** | Agrupa tareas relacionadas. Gestiona estados (planificación, activo, en pausa, completado), colaboradores e iconos personalizados. |
| ⏰ **Recordatorios** | Configura alertas para tareas, proyectos, rutinas u objetivos con frecuencia única, diaria, semanal o personalizada. |
| 🔄 **Rutinas** | Establece hábitos diarios, semanales, quincenales o mensuales con días específicos, horarios y duración. |
| 🎯 **Objetivos** | Define metas por categoría (salud, carrera, personal, finanzas, educación, relaciones) con seguimiento de progreso, hitos y plazos. |
| 📊 **Analíticas** | Visualiza tu productividad con gráficos interactivos (fl_chart): tareas completadas, tiempo invertido, tendencias. |
| 📅 **Calendario** | Vista de calendario integrada para organizar visualmente tus actividades. |
| 👤 **Autenticación** | Registro, login con JWT, verificación de email y aceptación de LOPD. |
| 👥 **Perfil de usuario** | Gestión de datos personales, foto de perfil y configuración de cuenta. |
| 🎨 **Temas** | Soporte para tema claro y oscuro con diseño Material Design. |

---

## Arquitectura y Estructura del Proyecto

### Patrón de Arquitectura

La aplicación sigue el patrón **Provider** para la gestión de estado en Flutter, con una arquitectura de **capas separadas**:

```
┌──────────────────────────────────────────────────┐
│                   FRONTEND (Flutter)              │
│  ┌──────────┐  ┌───────────┐  ┌───────────────┐  │
│  │ Screens  │◄─│ Providers │◄─│   Services    │  │
│  │  (UI)    │  │  (Estado) │  │ (API/Storage) │  │
│  └──────────┘  └───────────┘  └───────┬───────┘  │
│                                       │          │
└───────────────────────────────────────┼──────────┘
                                        │ HTTP/REST
┌───────────────────────────────────────┼──────────┐
│                   BACKEND (Node.js)   │          │
│  ┌──────────┐  ┌───────────┐  ┌──────┴────────┐  │
│  │  Routes  │◄─│ Middleware│◄─│    Express    │  │
│  │  (API)   │  │  (Auth)   │  │   (Server)    │  │
│  └────┬─────┘  └───────────┘  └───────────────┘  │
│       │                                          │
│  ┌────┴─────┐                                    │
│  │  MySQL   │                                    │
│  │   (BD)   │                                    │
│  └──────────┘                                    │
└──────────────────────────────────────────────────┘
```

### Estructura de Directorios

```
zen/
├── lib/                          # Código fuente Flutter
│   ├── main.dart                 # Punto de entrada de la app
│   ├── models/                   # Modelos de datos (Task, Project, User, etc.)
│   │   ├── goal.dart
│   │   ├── project.dart
│   │   ├── reminder.dart
│   │   ├── routine.dart
│   │   ├── task.dart
│   │   └── user.dart
│   ├── providers/                # Gestión de estado (Provider pattern)
│   │   ├── analytics_provider.dart
│   │   ├── auth_provider.dart
│   │   ├── project_provider.dart
│   │   ├── reminder_provider.dart
│   │   └── task_provider.dart
│   ├── screens/                  # Pantallas de la app
│   │   ├── analytics_screen.dart
│   │   ├── calendar_screen.dart
│   │   ├── home_screen.dart
│   │   ├── login_screen.dart
│   │   ├── profile_screen.dart
│   │   └── projects_screen.dart
│   ├── services/                 # Servicios de negocio
│   │   ├── analytics_service.dart
│   │   ├── api_service.dart      # Cliente HTTP para la API REST
│   │   ├── auth_service.dart     # Autenticación y tokens
│   │   ├── database_service.dart # Almacenamiento local
│   │   ├── data_sync_service.dart# Sincronización de datos
│   │   └── token_service.dart    # Gestión de JWT
│   ├── theme/                    # Temas claro/oscuro
│   ├── utils/                    # Utilidades y helpers
│   └── widgets/                  # Componentes reutilizables
│
├── zen-backend/                  # Servidor API REST
│   ├── server.js                 # Configuración Express + MySQL
│   ├── init-db.js                # Script de inicialización de BD
│   ├── package.json
│   └── routes/                   # Rutas del API
│       ├── auth.js               # /api/auth  (login, registro)
│       ├── tasks.js              # /api/tasks
│       ├── projects.js           # /api/projects
│       ├── reminders.js          # /api/reminders
│       ├── routines.js           # /api/routines
│       ├── goals.js              # /api/goals
│       └── users.js              # /api/users
│
├── android/                      # Configuración nativa Android
├── ios/                          # Configuración nativa iOS
├── web/                          # Configuración Web
├── windows/                      # Configuración Windows
├── macos/                        # Configuración macOS
├── linux/                        # Configuración Linux
├── test/                         # Tests
├── pubspec.yaml                  # Dependencias Flutter
└── analysis_options.yaml         # Reglas de análisis estático
```

---

## Requisitos Previos

| Herramienta | Versión Mínima | Descripción |
|-------------|---------------|-------------|
| **Flutter SDK** | 3.10+ | Framework UI multiplataforma |
| **Dart SDK** | 3.10+ | Incluido con Flutter |
| **Node.js** | 18+ | Runtime del backend |
| **npm** | 9+ | Gestor de paquetes Node.js |
| **MySQL** | 8.0+ | Base de datos relacional |
| **Git** | 2.30+ | Control de versiones |

### Herramientas Opcionales

- **Android Studio** / **Xcode**: Para desarrollo móvil nativo
- **VS Code** con extensiones Flutter y Dart
- **Postman** o **Thunder Client**: Para probar la API
- **MySQL Workbench**: Para gestionar la base de datos

---

## Instalación y Ejecución

### 1. Clonar el Repositorio

```bash
git clone https://github.com/BHMario/zen.git
cd zen
```

### 2. Configurar la Base de Datos (MySQL)

```bash
# Acceder a MySQL
mysql -u root -p

# Crear la base de datos (o usar el script automático)
CREATE DATABASE IF NOT EXISTS zen_db;
EXIT;
```

### 3. Backend (Node.js + Express)

```bash
# Navegar al directorio del backend
cd zen-backend

# Instalar dependencias
npm install

# Crear archivo de variables de entorno
cp .env.example .env   # o crear manualmente (ver sección de configuración)

# Inicializar las tablas de la BD
node init-db.js

# Iniciar el servidor en modo desarrollo
npm run dev

# O en modo producción
npm start
```

El servidor arrancará en `http://localhost:3000`. Verifica con:
```bash
curl http://localhost:3000/health
# Respuesta: {"status":"OK","timestamp":"..."}
```

### 4. Frontend (Flutter)

```bash
# Volver al directorio raíz
cd ..

# Instalar dependencias de Flutter
flutter pub get

# Verificar que el entorno está correcto
flutter doctor

# Ejecutar en modo debug
flutter run

# Ejecutar en un dispositivo específico
flutter run -d chrome       # Web
flutter run -d windows      # Windows
flutter run -d android      # Android (emulador o dispositivo)
flutter run -d ios           # iOS (solo en macOS)

# Compilar para producción
flutter build apk            # Android APK
flutter build appbundle      # Android App Bundle
flutter build web            # Web
flutter build windows        # Windows
flutter build ios            # iOS
```

### 5. Ejecución Completa (Resumen Rápido)

```bash
# Terminal 1 - Backend
cd zen-backend && npm run dev

# Terminal 2 - Frontend
cd zen && flutter run -d chrome
```

---

## Configuración de Variables de Entorno

Crea un archivo `.env` en `zen-backend/`:

```env
# Servidor
PORT=3000

# Base de Datos MySQL
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=tu_contraseña
DB_NAME=zen_db

# JWT
JWT_SECRET=tu_clave_secreta_jwt
JWT_EXPIRATION=24h
```

---

## API REST - Endpoints

### Base URL: `http://localhost:3000/api`

| Método | Endpoint | Descripción | Auth |
|--------|----------|-------------|------|
| `POST` | `/auth/register` | Registro de usuario | No |
| `POST` | `/auth/login` | Inicio de sesión (devuelve JWT) | No |
| `GET` | `/tasks` | Obtener tareas del usuario | Sí |
| `POST` | `/tasks` | Crear nueva tarea | Sí |
| `PUT` | `/tasks/:id` | Actualizar tarea | Sí |
| `DELETE` | `/tasks/:id` | Eliminar tarea | Sí |
| `GET` | `/projects` | Obtener proyectos del usuario | Sí |
| `POST` | `/projects` | Crear nuevo proyecto | Sí |
| `PUT` | `/projects/:id` | Actualizar proyecto | Sí |
| `DELETE` | `/projects/:id` | Eliminar proyecto | Sí |
| `GET` | `/reminders` | Obtener recordatorios | Sí |
| `POST` | `/reminders` | Crear recordatorio | Sí |
| `PUT` | `/reminders/:id` | Actualizar recordatorio | Sí |
| `DELETE` | `/reminders/:id` | Eliminar recordatorio | Sí |
| `GET` | `/routines` | Obtener rutinas | Sí |
| `POST` | `/routines` | Crear rutina | Sí |
| `PUT` | `/routines/:id` | Actualizar rutina | Sí |
| `DELETE` | `/routines/:id` | Eliminar rutina | Sí |
| `GET` | `/goals` | Obtener objetivos | Sí |
| `POST` | `/goals` | Crear objetivo | Sí |
| `PUT` | `/goals/:id` | Actualizar objetivo | Sí |
| `DELETE` | `/goals/:id` | Eliminar objetivo | Sí |
| `GET` | `/users/profile` | Obtener perfil de usuario | Sí |
| `PUT` | `/users/profile` | Actualizar perfil | Sí |
| `GET` | `/health` | Health check del servidor | No |

---

## Casos de Uso

### Diagrama General de Casos de Uso

```
                          ┌─────────────────────────────────────────────┐
                          │              Sistema ZEN                     │
                          │                                             │
                          │  ┌───────────────────┐                      │
                          │  │ CU01: Registrarse  │                     │
                          │  └─────────┬─────────┘                      │
                          │            │                                │
                          │  ┌─────────┴─────────┐                      │
                          │  │ CU02: Iniciar      │                     │
         ┌──────┐         │  │       sesión       │                     │
         │      │         │  └─────────┬─────────┘                      │
         │      │────────►│            │                                │
         │ User │         │  ┌─────────┴─────────┐                      │
         │      │────────►│  │ CU03: Gestionar   │                     │
         │      │         │  │       tareas       │                     │
         └──────┘         │  └─────────┬─────────┘                      │
                          │            │                                │
                          │  ┌─────────┴─────────┐                      │
                          │  │ CU04: Gestionar   │                     │
                          │  │     proyectos      │                     │
                          │  └─────────┬─────────┘                      │
                          │            │                                │
                          │  ┌─────────┴─────────┐                      │
                          │  │ CU05: Configurar  │                     │
                          │  │   recordatorios    │                     │
                          │  └─────────┬─────────┘                      │
                          │            │                                │
                          │  ┌─────────┴─────────┐                      │
                          │  │ CU06: Gestionar   │                     │
                          │  │      rutinas       │                     │
                          │  └─────────┬─────────┘                      │
                          │            │                                │
                          │  ┌─────────┴─────────┐                      │
                          │  │ CU07: Definir     │                     │
                          │  │     objetivos      │                     │
                          │  └─────────┬─────────┘                      │
                          │            │                                │
                          │  ┌─────────┴─────────┐                      │
                          │  │ CU08: Ver         │                     │
                          │  │   analíticas       │                     │
                          │  └─────────┬─────────┘                      │
                          │            │                                │
                          │  ┌─────────┴─────────┐                      │
                          │  │ CU09: Gestionar   │                     │
                          │  │      perfil        │                     │
                          │  └───────────────────┘                      │
                          └─────────────────────────────────────────────┘
```

### Detalle de Casos de Uso

#### CU01 - Registrarse
| Campo | Descripción |
|-------|-------------|
| **Actor** | Usuario no registrado |
| **Precondición** | No tener cuenta en el sistema |
| **Flujo principal** | 1. El usuario accede a la pantalla de registro<br>2. Introduce nombre, email y contraseña<br>3. Acepta la política LOPD<br>4. El sistema valida los datos y crea la cuenta<br>5. Se redirige al login |
| **Postcondición** | Usuario registrado en la BD |

#### CU02 - Iniciar Sesión
| Campo | Descripción |
|-------|-------------|
| **Actor** | Usuario registrado |
| **Precondición** | Tener cuenta en el sistema |
| **Flujo principal** | 1. El usuario introduce email y contraseña<br>2. El sistema valida las credenciales<br>3. Se genera un token JWT<br>4. Se redirige a la pantalla principal |
| **Flujo alternativo** | Credenciales incorrectas → Se muestra mensaje de error |
| **Postcondición** | Sesión activa con JWT válido |

#### CU03 - Gestionar Tareas
| Campo | Descripción |
|-------|-------------|
| **Actor** | Usuario autenticado |
| **Precondición** | Sesión activa |
| **Flujo principal** | 1. El usuario accede al listado de tareas<br>2. Puede crear, editar, eliminar o cambiar estado<br>3. Asigna prioridad, fecha límite, etiquetas y proyecto<br>4. Las tareas se sincronizan con el servidor |
| **Postcondición** | Tareas actualizadas en BD |

#### CU04 - Gestionar Proyectos
| Campo | Descripción |
|-------|-------------|
| **Actor** | Usuario autenticado |
| **Precondición** | Sesión activa |
| **Flujo principal** | 1. El usuario crea un proyecto con nombre, descripción y color<br>2. Asigna tareas al proyecto<br>3. Cambia el estado del proyecto<br>4. Puede añadir colaboradores |
| **Postcondición** | Proyecto y asociaciones actualizados |

#### CU05 - Configurar Recordatorios
| Campo | Descripción |
|-------|-------------|
| **Actor** | Usuario autenticado |
| **Precondición** | Existir al menos una tarea, proyecto, rutina u objetivo |
| **Flujo principal** | 1. El usuario selecciona un elemento<br>2. Configura fecha/hora y frecuencia<br>3. Añade un mensaje personalizado (opcional)<br>4. Activa el recordatorio |
| **Postcondición** | Recordatorio programado y activo |

#### CU06 - Gestionar Rutinas
| Campo | Descripción |
|-------|-------------|
| **Actor** | Usuario autenticado |
| **Precondición** | Sesión activa |
| **Flujo principal** | 1. El usuario crea una rutina con nombre y frecuencia<br>2. Selecciona días de la semana (si aplica)<br>3. Define horario y duración<br>4. Puede compartir con otros usuarios |
| **Postcondición** | Rutina creada y programada |

#### CU07 - Definir Objetivos
| Campo | Descripción |
|-------|-------------|
| **Actor** | Usuario autenticado |
| **Precondición** | Sesión activa |
| **Flujo principal** | 1. El usuario define un objetivo con título y categoría<br>2. Establece valor objetivo, unidad y fecha límite<br>3. Actualiza el progreso periódicamente<br>4. Marca hitos alcanzados |
| **Postcondición** | Objetivo creado con seguimiento de progreso |

#### CU08 - Ver Analíticas
| Campo | Descripción |
|-------|-------------|
| **Actor** | Usuario autenticado |
| **Precondición** | Tener datos de actividad registrados |
| **Flujo principal** | 1. El usuario accede a la sección de analíticas<br>2. Visualiza gráficos de productividad<br>3. Consulta estadísticas de tareas, proyectos y objetivos<br>4. Filtra por periodo de tiempo |
| **Postcondición** | Datos visualizados correctamente |

#### CU09 - Gestionar Perfil
| Campo | Descripción |
|-------|-------------|
| **Actor** | Usuario autenticado |
| **Precondición** | Sesión activa |
| **Flujo principal** | 1. El usuario accede a la sección de perfil<br>2. Edita nombre, teléfono o imagen de perfil<br>3. Guarda los cambios<br>4. Puede cerrar sesión |
| **Postcondición** | Perfil actualizado |

---

## Requisitos Funcionales

| ID | Requisito | Prioridad | Módulo |
|----|-----------|-----------|--------|
| **RF01** | El sistema debe permitir el registro de usuarios con nombre, email y contraseñacontraseña | Alta | Auth |
| **RF02** | El sistema debe autenticar usuarios mediante JWT | Alta | Auth |
| **RF03** | El usuario debe aceptar la política LOPD al registrarse | Alta | Auth |
| **RF04** | El sistema debe permitir crear, leer, actualizar y eliminar tareas (CRUD) | Alta | Tareas |
| **RF05** | Las tareas deben tener estados: pendiente, en progreso, completada, cancelada | Alta | Tareas |
| **RF06** | Las tareas deben permitir asignar prioridad: baja, media, alta, urgente | Alta | Tareas |
| **RF07** | Las tareas deben poder asociarse a un proyecto | Media | Tareas |
| **RF08** | Las tareas deben soportar etiquetas, fecha límite y horas estimadas/reales | Media | Tareas |
| **RF09** | El sistema debe permitir CRUD de proyectos con estados definidos | Alta | Proyectos |
| **RF10** | Los proyectos deben poder contener múltiples tareas | Alta | Proyectos |
| **RF11** | Los proyectos deben permitir añadir colaboradores | Media | Proyectos |
| **RF12** | El sistema debe permitir configurar recordatorios con frecuencia personalizable | Alta | Recordatorios |
| **RF13** | Los recordatorios deben poder asociarse a tareas, proyectos, rutinas u objetivos | Media | Recordatorios |
| **RF14** | El sistema debe permitir CRUD de rutinas con frecuencia y días específicos | Alta | Rutinas |
| **RF15** | Las rutinas deben poder compartirse entre usuarios | Baja | Rutinas |
| **RF16** | El sistema debe permitir definir objetivos con categorías y seguimiento de progreso | Alta | Objetivos |
| **RF17** | Los objetivos deben permitir definir hitos intermedios | Media | Objetivos |
| **RF18** | El sistema debe mostrar gráficos y estadísticas de productividad | Media | Analíticas |
| **RF19** | El usuario debe poder editar su perfil (nombre, teléfono, imagen) | Media | Perfil |
| **RF20** | El sistema debe soportar vista de calendario para todas las actividades | Media | Calendario |
| **RF21** | El sistema debe sincronizar datos entre el frontend y el backend | Alta | Sync |
| **RF22** | El sistema debe mantener almacenamiento local para modo offline | Media | Storage |

---

## Requisitos No Funcionales

| ID | Requisito | Categoría |
|----|-----------|-----------|
| **RNF01** | La aplicación debe funcionar en Android, iOS, Web y escritorio (Windows, macOS, Linux) | Portabilidad |
| **RNF02** | El tiempo de respuesta de la API no debe superar los 500ms por petición | Rendimiento |
| **RNF03** | La interfaz debe seguir las directrices de Material Design | Usabilidad |
| **RNF04** | Las contraseñas deben almacenarse hasheadas con bcrypt | Seguridad |
| **RNF05** | La comunicación cliente-servidor debe usar tokens JWT | Seguridad |
| **RNF06** | La base de datos debe soportar conexiones concurrentes (pool de 10 conexiones) | Rendimiento |
| **RNF07** | La aplicación debe soportar tema claro y oscuro | Usabilidad |
| **RNF08** | El sistema debe cumplir con la normativa LOPD en cuanto a datos personales | Legal |
| **RNF09** | El código debe seguir las reglas de análisis estático de `flutter_lints` | Mantenibilidad |
| **RNF10** | La API debe manejar errores de forma consistente con códigos HTTP estándar | Fiabilidad |
| **RNF11** | La aplicación debe tener un tiempo de inicio inferior a 3 segundos | Rendimiento |
| **RNF12** | El backend debe incluir health check endpoint para monitorización | Disponibilidad |
| **RNF13** | Las fechas deben localizarse al formato español (`es_ES`) | Usabilidad |
| **RNF14** | El sistema debe usar UUIDs (v4) como identificadores primarios | Interoperabilidad |

---

## Esquema Entidad-Relación

```
┌──────────────────┐       ┌──────────────────────┐       ┌──────────────────┐
│      USERS       │       │        TASKS          │       │    PROJECTS      │
├──────────────────┤       ├──────────────────────┤       ├──────────────────┤
│ PK id (UUID)     │       │ PK id (UUID)          │       │ PK id (UUID)     │
│    name          │       │ FK user_id → users     │       │ FK user_id       │
│    email (UQ)    │       │    title               │       │    name          │
│    password      │       │    description         │       │    description   │
│    phone         │       │    due_date            │       │    color         │
│    lopd_accepted │       │    status              │       │    start_date    │
│    created_at    │       │    priority            │       │    end_date      │
│    updated_at    │       │ FK project_id → projects│      │    status        │
└────────┬─────────┘       │    color               │       │ FK created_by    │
         │                 │    labels              │       │    created_at    │
         │  1         N    │    estimated_hours     │       │    updated_at    │
         ├────────────────►│    actual_hours        │       └────────┬─────────┘
         │                 │ FK created_by → users   │                │
         │                 │    created_at           │        N       │
         │                 │    updated_at           │◄───────────────┘
         │                 └──────────────────────┘
         │
         │  1         N    ┌──────────────────────┐
         ├────────────────►│     REMINDERS         │
         │                 ├──────────────────────┤
         │                 │ PK id (UUID)          │
         │                 │    item_id            │
         │                 │    type               │
         │                 │    date_time          │
         │                 │    frequency          │
         │                 │    message            │
         │                 │    is_active          │
         │                 │ FK created_by → users  │
         │                 │    created_at          │
         │                 │    updated_at          │
         │                 └──────────────────────┘
         │
         │  1         N    ┌──────────────────────┐
         ├────────────────►│      ROUTINES         │
         │                 ├──────────────────────┤
         │                 │ PK id (UUID)          │
         │                 │ FK user_id → users     │
         │                 │    title              │
         │                 │    description        │
         │                 │    frequency          │
         │                 │    days_of_week       │
         │                 │    color              │
         │                 │ FK created_by → users  │
         │                 │    created_at          │
         │                 │    updated_at          │
         │                 └──────────────────────┘
         │
         │  1         N    ┌──────────────────────┐
         └────────────────►│       GOALS           │
                           ├──────────────────────┤
                           │ PK id (UUID)          │
                           │ FK user_id → users     │
                           │    title              │
                           │    description        │
                           │    category           │
                           │    target_date        │
                           │    progress           │
                           │    status             │
                           │    color              │
                           │ FK created_by → users  │
                           │    created_at          │
                           │    updated_at          │
                           └──────────────────────┘
```

### Relaciones

| Relación | Tipo | Descripción |
|----------|------|-------------|
| Users → Tasks | 1:N | Un usuario posee muchas tareas |
| Users → Projects | 1:N | Un usuario crea muchos proyectos |
| Users → Reminders | 1:N | Un usuario configura muchos recordatorios |
| Users → Routines | 1:N | Un usuario tiene muchas rutinas |
| Users → Goals | 1:N | Un usuario define muchos objetivos |
| Projects → Tasks | 1:N | Un proyecto agrupa muchas tareas |

---

## Normalización de la Base de Datos

La base de datos MySQL (`zen_db`) está normalizada hasta la **Tercera Forma Normal (3FN)**.

### Primera Forma Normal (1FN) ✅
> *Todos los atributos contienen valores atómicos y cada registro es único.*

- Cada tabla tiene una clave primaria definida (`id` UUID).
- No hay grupos repetitivos. Los campos como `labels` y `days_of_week` se almacenan como TEXT serializado (formato JSON), manteniendo atomicidad a nivel de columna.
- Cada celda contiene un único valor.

### Segunda Forma Normal (2FN) ✅
> *Está en 1FN y todos los atributos no clave dependen completamente de la clave primaria.*

- Todas las tablas tienen claves primarias simples (UUID), por lo que no hay dependencias parciales posibles.
- Cada atributo no clave depende exclusivamente del `id` de su tabla.

| Tabla | Clave Primaria | Dependencias completas |
|-------|---------------|----------------------|
| `users` | `id` | name, email, password, phone → dependen totalmente de `id` |
| `tasks` | `id` | title, description, status, priority → dependen totalmente de `id` |
| `projects` | `id` | name, description, color, status → dependen totalmente de `id` |
| `reminders` | `id` | item_id, type, date_time → dependen totalmente de `id` |
| `routines` | `id` | title, frequency, days_of_week → dependen totalmente de `id` |
| `goals` | `id` | title, category, progress → dependen totalmente de `id` |

### Tercera Forma Normal (3FN) ✅
> *Está en 2FN y no existen dependencias transitivas.*

- No hay atributos no clave que dependan de otros atributos no clave.
- Los campos `created_by` y `user_id` son claves foráneas que referencian a `users(id)`, no relaciones transitivas.
- Los timestamps (`created_at`, `updated_at`) son gestionados automáticamente por MySQL.

**Ejemplo de verificación en la tabla `tasks`:**
```
tasks.id → tasks.title          ✅ (directa)
tasks.id → tasks.user_id        ✅ (directa, FK)
tasks.id → tasks.project_id     ✅ (directa, FK)
tasks.user_id → users.name      ❌ NO almacenado en tasks (se consulta vía JOIN)
```

### Índices Definidos

```sql
-- Tabla tasks
INDEX idx_user_id (user_id)
INDEX idx_due_date (due_date)

-- Tabla projects
INDEX idx_user_id (user_id)

-- Tabla reminders
INDEX idx_item_id (item_id)
INDEX idx_date_time (date_time)

-- Tabla routines
INDEX idx_user_id (user_id)

-- Tabla goals
INDEX idx_user_id (user_id)
```

---

## Diagrama de Gantt

### Planificación del Proyecto

```
DIAGRAMA DE GANTT - Proyecto ZEN
═══════════════════════════════════════════════════════════════════════════════

Fase / Tarea                  │ Ene 26 │ Feb 26 │ Mar 26 │ Abr 26 │ May 26 │ Jun 26 │
                              │ S1│ S2│ S3│ S4│ S1│ S2│ S3│ S4│ S1│ S2│ S3│ S4│ S1│ S2│ S3│ S4│ S1│ S2│ S3│ S4│ S1│ S2│ S3│ S4│
──────────────────────────────┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┤
FASE 1: ANÁLISIS Y DISEÑO    │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │
  Análisis de requisitos      │ ██│ ██│   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │
  Diseño de BD (E-R)          │   │ ██│ ██│   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │
  Diseño de UI/UX             │   │   │ ██│ ██│   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │
  Arquitectura del sistema    │   │   │   │ ██│ ██│   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │
──────────────────────────────┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┤
FASE 2: BACKEND               │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │
  Configuración servidor      │   │   │   │   │ ██│ ██│   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │
  Modelo de datos (MySQL)     │   │   │   │   │   │ ██│ ██│   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │
  API Auth (registro/login)   │   │   │   │   │   │   │ ██│ ██│   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │
  API CRUD (tareas/proyectos) │   │   │   │   │   │   │   │ ██│ ██│ ██│   │   │   │   │   │   │   │   │   │   │   │   │   │   │
  API (recordatorios/rutinas) │   │   │   │   │   │   │   │   │   │ ██│ ██│   │   │   │   │   │   │   │   │   │   │   │   │   │
  API (objetivos/usuarios)    │   │   │   │   │   │   │   │   │   │   │ ██│ ██│   │   │   │   │   │   │   │   │   │   │   │   │
──────────────────────────────┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┤
FASE 3: FRONTEND               │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │
  Estructura Flutter + Theme  │   │   │   │   │   │   │   │   │   │   │   │ ██│ ██│   │   │   │   │   │   │   │   │   │   │   │
  Pantalla Login/Registro     │   │   │   │   │   │   │   │   │   │   │   │   │ ██│ ██│   │   │   │   │   │   │   │   │   │   │
  Pantalla Home + Navegación  │   │   │   │   │   │   │   │   │   │   │   │   │   │ ██│ ██│   │   │   │   │   │   │   │   │   │
  Pantalla Tareas             │   │   │   │   │   │   │   │   │   │   │   │   │   │   │ ██│ ██│   │   │   │   │   │   │   │   │
  Pantalla Proyectos          │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │ ██│ ██│   │   │   │   │   │   │   │
  Pantalla Calendario         │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │ ██│ ██│   │   │   │   │   │   │
  Pantalla Analíticas         │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │ ██│ ██│   │   │   │   │   │
  Pantalla Perfil             │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │ ██│   │   │   │   │   │
──────────────────────────────┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┤
FASE 4: INTEGRACIÓN Y TESTING │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │
  Integración Frontend-Backend│   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │ ██│ ██│   │   │   │   │
  Testing y corrección bugs   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │ ██│ ██│   │   │   │
  Optimización y rendimiento  │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │ ██│ ██│   │   │
──────────────────────────────┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┤
FASE 5: DOCUMENTACIÓN Y DEPLOY│   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │
  Documentación técnica       │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │ ██│ ██│   │
  Despliegue y entrega        │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │   │ ██│ ██│
══════════════════════════════╧═══╧═══╧═══╧═══╧═══╧═══╧═══╧═══╧═══╧═══╧═══╧═══╧═══╧═══╧═══╧═══╧═══╧═══╧═══╧═══╧═══╧═══╧═══╧═══╧

Leyenda: ██ = Periodo de trabajo activo | S = Semana
Duración total estimada: 6 meses (Enero 2026 - Junio 2026)
```

### Resumen de Fases

| Fase | Duración | Periodo |
|------|----------|---------|
| 1. Análisis y Diseño | 5 semanas | Ene S1 - Feb S1 |
| 2. Backend | 8 semanas | Feb S1 - Mar S4 |
| 3. Frontend | 8 semanas | Mar S4 - May S3 |
| 4. Integración y Testing | 4 semanas | May S3 - Jun S2 |
| 5. Documentación y Deploy | 3 semanas | Jun S1 - Jun S4 |

---

## Análisis DAFO

### Matriz DAFO del Proyecto Zen

```
                        FACTORES POSITIVOS            FACTORES NEGATIVOS
                    ┌─────────────────────────┬─────────────────────────┐
                    │                         │                         │
                    │       FORTALEZAS        │       DEBILIDADES       │
                    │                         │                         │
   ORIGEN           │ • Multiplataforma       │ • Equipo de desarrollo  │
   INTERNO          │   (6 plataformas)       │   reducido              │
                    │ • Stack tecnológico     │ • Sin notificaciones    │
                    │   moderno (Flutter +    │   push nativas (aún)    │
                    │   Node.js)              │ • Dependencia de        │
                    │ • Diseño UI/UX limpio   │   conexión para sync    │
                    │   con Material Design   │ • Sin sistema de        │
                    │ • API REST bien         │   backups automáticos   │
                    │   estructurada          │ • Testing limitado en   │
                    │ • BD normalizada (3FN)  │   fase inicial          │
                    │ • Autenticación segura  │                         │
                    │   (JWT + bcrypt)        │                         │
                    │ • Cumplimiento LOPD     │                         │
                    │                         │                         │
                    ├─────────────────────────┼─────────────────────────┤
                    │                         │                         │
                    │     OPORTUNIDADES       │       AMENAZAS          │
                    │                         │                         │
   ORIGEN           │ • Creciente demanda de  │ • Alta competencia      │
   EXTERNO          │   apps de productividad │   (Todoist, Notion,     │
                    │ • Integración futura    │   TickTick, etc.)       │
                    │   con calendarios       │ • Cambios frecuentes    │
                    │   externos (Google,     │   en Flutter/Dart SDK   │
                    │   Outlook)              │ • Expectativas altas    │
                    │ • Monetización vía      │   de los usuarios en    │
                    │   modelo freemium       │   cuanto a UX           │
                    │ • Expansión a equipos   │ • Posibles problemas    │
                    │   y uso empresarial     │   de escalabilidad      │
                    │ • Gamificación del      │   con MySQL básico      │
                    │   seguimiento de metas  │ • Regulaciones de       │
                    │ • IA para sugerencias   │   privacidad cambiantes │
                    │   de productividad      │                         │
                    │                         │                         │
                    └─────────────────────────┴─────────────────────────┘
```

### Estrategias derivadas del DAFO

| Estrategia | Tipo | Descripción |
|------------|------|-------------|
| **Aprovechar multiplataforma** | FO (Fortaleza + Oportunidad) | Usar la ventaja de 6 plataformas para llegar a más usuarios en el mercado creciente de productividad |
| **Implementar IA** | FO | Aprovechar la API REST existente para integrar modelos de IA que sugieran prioridades y patrones de productividad |
| **Ampliar testing** | DA (Debilidad + Amenaza) | Incrementar la cobertura de tests para competir en calidad con apps consolidadas |
| **Notificaciones push** | DO (Debilidad + Oportunidad) | Implementar Firebase Cloud Messaging para notificaciones nativas y mejorar la retención |
| **Plan de escalabilidad** | DA | Diseñar migración a cloud (AWS/Azure) antes de alcanzar límites de MySQL local |
| **Modo offline robusto** | FA (Fortaleza + Amenaza) | Potenciar el almacenamiento local existente para diferenciarse de competidores que requieren conexión |

---

## Stack Tecnológico

### Frontend
| Tecnología | Versión | Uso |
|------------|---------|-----|
| Flutter | 3.10+ | Framework UI multiplataforma |
| Dart | 3.10+ | Lenguaje de programación |
| Provider | 6.1+ | Gestión de estado |
| fl_chart | 0.65+ | Gráficos y visualizaciones |
| http | 1.1+ | Cliente HTTP para API REST |
| shared_preferences | 2.2+ | Almacenamiento local (key-value) |
| intl | 0.19+ | Internacionalización y formateo de fechas |
| crypto | 3.0+ | Hashing de datos |
| uuid | 4.0+ | Generación de identificadores únicos |

### Backend
| Tecnología | Versión | Uso |
|------------|---------|-----|
| Node.js | 18+ | Runtime de servidor |
| Express | 4.18+ | Framework HTTP |
| MySQL2 | 3.6+ | Driver de base de datos |
| jsonwebtoken | 9.0+ | Autenticación JWT |
| bcryptjs | 2.4+ | Hashing de contraseñas |
| cors | 2.8+ | Política de CORS |
| dotenv | 16.0+ | Variables de entorno |
| uuid | 9.0+ | Generación de UUIDs |
| nodemon | 3.0+ | Hot reload en desarrollo |

### Base de Datos
| Tecnología | Versión | Uso |
|------------|---------|-----|
| MySQL | 8.0+ | Base de datos relacional principal |

---

## Licencia

Este proyecto está bajo la licencia **MIT**. Consulta el archivo [LICENSE](LICENSE) para más detalles.

---

## Autor

Desarrollado por **Mario Sanchez, Luis Capel y Marco Antonio Caballero** —
[GitHub: @BHMario](https://github.com/BHMario)

---

<p align="center">
  <em>Zen — Encuentra tu equilibrio. Maximiza tu productividad.</em>
</p>
