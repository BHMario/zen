# Zen - Gestor de Productividad

Una aplicación Flutter diseñada para ayudarte a organizar tus tareas, proyectos, recordatorios y rutinas diarias. Zen es tu compañero perfecto para mantener un estilo de vida equilibrado y productivo.

## Características

- 📋 **Gestión de Tareas**: Crea, organiza y completa tareas fácilmente
- 📁 **Proyectos**: Agrupa tareas relacionadas en proyectos
- ⏰ **Recordatorios**: Configura recordatorios para no perder de vista lo importante
- 🔄 **Rutinas**: Establece rutinas diarias para mantener hábitos saludables
- 📊 **Análisis**: Visualiza tu productividad con gráficos y estadísticas
- 👤 **Autenticación**: Sistema seguro de login y gestión de usuarios
- 🎨 **Interfaz intuitiva**: Diseño moderno y fácil de usar

## Estructura del Proyecto

```
lib/
├── main.dart              # Punto de entrada de la aplicación
├── models/                # Modelos de datos
├── providers/             # Gestión de estado y lógica de negocio
├── screens/               # Pantallas de la aplicación
├── services/              # Servicios (API, almacenamiento)
├── theme/                 # Temas y estilos
├── utils/                 # Utilidades y helpers
└── widgets/               # Componentes reutilizables

zen-backend/              # Backend Node.js
├── server.js              # Servidor principal
├── init-db.js             # Inicialización de base de datos
├── package.json
└── routes/                # Rutas del API
```

## Requisitos Previos

- Flutter SDK (v3.0 o superior)
- Dart SDK
- Node.js (para el backend)
- npm o yarn

## Instalación

### Frontend (Flutter)

1. Clona el repositorio:
```bash
git clone <url-del-repositorio>
cd zen
```

2. Instala las dependencias de Flutter:
```bash
flutter pub get
```

3. Ejecuta la aplicación:
```bash
flutter run
```

### Backend (Node.js)

1. Navega a la carpeta del backend:
```bash
cd zen-backend
```

2. Instala las dependencias:
```bash
npm install
```

3. Inicia el servidor:
```bash
npm start
```

## Desarrollo

Para comenzar con el desarrollo en Flutter, consulta la
[documentación oficial](https://docs.flutter.dev/), que incluye tutoriales,
ejemplos, guías de desarrollo móvil y referencia completa de API.

## Recursos Útiles

- [Laboratorio: Escribe tu primera app Flutter](https://docs.flutter.dev/get-started/codelab)
- [Recetario: Ejemplos útiles de Flutter](https://docs.flutter.dev/cookbook)

## Licencia

Este proyecto está bajo licencia [especificar licencia]

## Contacto

Para más información o contribuciones, por favor contacta al equipo de desarrollo.
