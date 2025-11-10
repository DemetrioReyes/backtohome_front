# BackToHome - App Móvil Flutter

Aplicación móvil para la plataforma BackToHome - Sistema de personas desaparecidas en República Dominicana.

## 📱 Características

- ✅ Autenticación de usuarios (Login/Register)
- ✅ Ver personas desaparecidas cercanas
- ✅ Filtrar por radio de distancia
- ✅ Gestionar reportes propios
- ✅ Recibir alertas de personas desaparecidas
- ✅ Ver perfil y configuración
- 🚧 Crear reportes con fotos
- 🚧 Reportar avistamientos
- 🚧 Notificaciones push (FCM)
- 🚧 Mapa interactivo con Google Maps

## 🛠️ Tecnologías

- **Framework**: Flutter 3.9+
- **Lenguaje**: Dart
- **State Management**: Provider
- **HTTP Client**: Dio & HTTP
- **Maps**: Google Maps Flutter
- **Location**: Geolocator
- **Storage**: Shared Preferences & Flutter Secure Storage
- **Notifications**: Firebase Cloud Messaging
- **UI**: Material Design 3 + Google Fonts

## 📋 Prerequisitos

1. **Flutter SDK** (versión 3.9 o superior)
   ```bash
   flutter --version
   ```

2. **Android Studio** o **Xcode** (para emuladores)

3. **API Backend** - La URL del API de BackToHome

4. **Credenciales de Firebase** (para notificaciones push)

5. **Google Maps API Key** (para el mapa)

## 🚀 Instalación

### 1. Clonar el repositorio

```bash
cd ~/Desktop/backtohome_app
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar el API

Editar el archivo `lib/config/app_config.dart`:

```dart
static const String apiBaseUrl = 'https://tu-api-url.com';
```

### 4. Configurar Firebase (Notificaciones Push)

#### Android:
1. Descargar `google-services.json` desde Firebase Console
2. Colocar en `android/app/google-services.json`

#### iOS:
1. Descargar `GoogleService-Info.plist` desde Firebase Console
2. Colocar en `ios/Runner/GoogleService-Info.plist`

### 5. Configurar Google Maps

#### Android:
Editar `android/app/src/main/AndroidManifest.xml`:

```xml
<application>
    <meta-data
        android:name="com.google.android.geo.API_KEY"
        android:value="TU_GOOGLE_MAPS_API_KEY"/>
</application>
```

#### iOS:
Editar `ios/Runner/AppDelegate.swift`:

```swift
GMSServices.provideAPIKey("TU_GOOGLE_MAPS_API_KEY")
```

### 6. Ejecutar la aplicación

```bash
# Para Android
flutter run -d android

# Para iOS
flutter run -d ios

# Para Chrome (Web)
flutter run -d chrome
```

## 📁 Estructura del Proyecto

```
lib/
├── config/                 # Configuración y constantes
│   ├── app_config.dart    # Configuración de la app
│   └── app_theme.dart     # Tema y estilos
│
├── models/                 # Modelos de datos
│   ├── user.dart
│   ├── missing_person.dart
│   ├── alert.dart
│   ├── sighting.dart
│   └── found_report.dart
│
├── services/              # Servicios y lógica de negocio
│   ├── api_client.dart            # Cliente HTTP base
│   ├── auth_service.dart          # Autenticación
│   ├── missing_person_service.dart # Gestión de reportes
│   └── ...
│
├── screens/               # Pantallas de la app
│   ├── splash_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   ├── home_screen.dart       # Navegación principal
│   │   ├── map_tab.dart           # Tab de mapa
│   │   ├── alerts_tab.dart        # Tab de alertas
│   │   └── my_reports_tab.dart    # Tab de mis reportes
│   └── profile/
│       └── profile_screen.dart
│
├── widgets/               # Widgets reutilizables
│
├── utils/                 # Utilidades
│
└── main.dart             # Punto de entrada
```

## 🎨 Diseño y UI/UX

La aplicación utiliza un diseño moderno y intuitivo con:

- **Colores principales**:
  - Azul primario (#1E88E5)
  - Verde azulado secundario (#26A69A)
  - Naranja para alertas (#FF6F00)

- **Tipografía**:
  - Poppins para títulos
  - Inter para cuerpo de texto

- **Componentes**:
  - Material Design 3
  - Tarjetas con sombras suaves
  - Botones con bordes redondeados
  - Navegación por tabs inferior

## 🔐 Autenticación

La aplicación utiliza JWT (JSON Web Tokens) para autenticación:

1. El usuario se registra o inicia sesión
2. El API devuelve un token JWT
3. El token se guarda de forma segura usando Flutter Secure Storage
4. Todas las peticiones incluyen el token en el header `Authorization`

## 📡 Consumo del API

El servicio `ApiClient` maneja todas las peticiones HTTP:

```dart
// GET request
final response = await apiClient.get('/missing-persons/');

// POST request
final response = await apiClient.post(
  '/auth/login',
  body: {'email': email, 'password': password},
);

// POST con archivo (multipart)
final response = await apiClient.postMultipart(
  '/missing-persons/',
  fields: data,
  fileKey: 'photo',
  file: photoFile,
);
```

## 🗺️ Funcionalidades Principales

### 1. Registro y Login
- Validación de edad (18+)
- Contraseña segura (mínimo 8 caracteres)
- Almacenamiento seguro del token

### 2. Mapa de Personas Desaparecidas
- Lista de personas desaparecidas cercanas
- Filtro por radio de distancia (1-100 km)
- Pull-to-refresh para actualizar

### 3. Mis Reportes
- Ver reportes propios
- Estadísticas (alertas, avistamientos, hallazgos)
- Estados: Activo, Encontrado, Cancelado

### 4. Perfil
- Ver información personal
- Editar perfil
- Configurar notificaciones
- Cerrar sesión

## 🚧 Funcionalidades Pendientes

### Crear Reporte de Persona Desaparecida
- Formulario completo
- Subir foto principal y adicionales
- Seleccionar ubicación en mapa
- Validaciones de límites (máximo 2 reportes activos)

### Reportar Avistamiento
- Formulario con ubicación
- Foto opcional
- Notificación al reportante original

### Notificaciones Push
- Integración completa con FCM
- Recibir alertas de personas desaparecidas cercanas
- Notificaciones de avistamientos y hallazgos

### Mapa Interactivo
- Google Maps con markers
- Mostrar ubicación actual
- Markers de personas desaparecidas
- Filtros y clustering

## 🧪 Testing

```bash
# Ejecutar tests
flutter test

# Ejecutar tests con cobertura
flutter test --coverage

# Ver cobertura
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 📦 Build para Producción

### Android (APK)

```bash
flutter build apk --release
```

El APK estará en: `build/app/outputs/flutter-apk/app-release.apk`

### Android (App Bundle para Play Store)

```bash
flutter build appbundle --release
```

El bundle estará en: `build/app/outputs/bundle/release/app-release.aab`

### iOS (para App Store)

```bash
flutter build ios --release
```

Luego abrir en Xcode y subir a App Store Connect.

## 🔧 Troubleshooting

### Error: "No se pudo conectar al API"
- Verificar que la URL del API esté correcta en `app_config.dart`
- Verificar que el backend esté corriendo
- Verificar conexión a internet

### Error: "Google Maps no se muestra"
- Verificar que la API Key esté configurada correctamente
- Verificar que la API Key tenga habilitado "Maps SDK for Android/iOS"
- Verificar que el billing esté habilitado en Google Cloud

### Error de Firebase
- Verificar que los archivos `google-services.json` y `GoogleService-Info.plist` estén en las carpetas correctas
- Verificar que el package name coincida con Firebase Console

## 📞 Soporte

Para reportar bugs o solicitar funcionalidades:
- Email: rdemetrio72@yahoo.com
- GitHub Issues: [Link al repositorio]

## 📄 Licencia

Este proyecto es de código abierto bajo licencia MIT.

## 🙏 Agradecimientos

Proyecto desarrollado para ayudar a familias dominicanas a reencontrarse con sus seres queridos.

---

**BackToHome** - Ayudando a que las familias se reencuentren 🇩🇴
