# 🎯 Próximos Pasos de Desarrollo - BackToHome App

## Estado Actual del Proyecto

### ✅ Completado (70% del proyecto base)

#### Infraestructura
- ✅ Proyecto Flutter inicializado
- ✅ 19 archivos Dart creados
- ✅ 120+ dependencias instaladas
- ✅ Arquitectura limpia (Models, Services, Screens)
- ✅ State Management con Provider configurado
- ✅ Cliente HTTP con autenticación JWT
- ✅ Tema visual completo y profesional

#### Modelos de Datos
- ✅ User (usuario, perfil, ubicación, configuración)
- ✅ MissingPerson (persona desaparecida completa)
- ✅ Alert (alertas y notificaciones)
- ✅ Sighting (avistamientos)
- ✅ FoundReport (reportes de hallazgo)

#### Servicios API
- ✅ ApiClient (HTTP client base con JWT)
- ✅ AuthService (login, registro, logout)
- ✅ MissingPersonService (CRUD reportes)

#### Pantallas
- ✅ Splash Screen con verificación de auth
- ✅ Login Screen (validaciones completas)
- ✅ Register Screen (con fecha de nacimiento)
- ✅ Home Screen (navegación con tabs)
- ✅ Map Tab (lista de personas con filtros)
- ✅ Alerts Tab (estructura básica)
- ✅ My Reports Tab (con estadísticas)
- ✅ Profile Screen (con opciones)

---

## 🚧 Tareas Pendientes (30% restante)

### Prioridad 1: Funcionalidades Core

#### 1. Crear Reporte de Persona Desaparecida
**Archivos a crear:**
- `lib/screens/reports/create_report_screen.dart`
- `lib/screens/reports/select_location_screen.dart`
- `lib/widgets/photo_picker_widget.dart`

**Funcionalidades:**
- Formulario multi-paso (stepper)
  - Paso 1: Información básica (nombre, edad, género)
  - Paso 2: Descripción física
  - Paso 3: Última ubicación vista (con mapa)
  - Paso 4: Foto principal y adicionales
  - Paso 5: Información de contacto
- Validaciones:
  - Máximo 2 reportes activos
  - Foto obligatoria (máximo 5MB)
  - Ubicación requerida
- Upload de múltiples fotos con preview
- Selector de ubicación con Google Maps
- Integración con `MissingPersonService`

**Estimación:** 6-8 horas

---

#### 2. Detalle de Persona Desaparecida
**Archivos a crear:**
- `lib/screens/reports/missing_person_detail_screen.dart`
- `lib/widgets/photo_gallery_widget.dart`
- `lib/widgets/location_map_widget.dart`

**Funcionalidades:**
- Vista completa con toda la información
- Galería de fotos con zoom
- Mapa con marcador de última ubicación
- Botones de acción:
  - Reportar avistamiento
  - Reportar que lo encontré
  - Compartir (WhatsApp, Facebook, etc.)
  - Llamar al teléfono de contacto
- Timeline de avistamientos
- Contador de días desaparecido

**Estimación:** 4-5 horas

---

#### 3. Reportar Avistamiento
**Archivos a crear:**
- `lib/screens/reports/create_sighting_screen.dart`
- `lib/services/sighting_service.dart`

**Funcionalidades:**
- Formulario simple:
  - Fecha y hora del avistamiento
  - Ubicación (automática o manual)
  - Descripción (opcional)
  - Foto (opcional)
- Obtener ubicación actual automáticamente
- Upload de foto con preview
- Confirmación antes de enviar
- Notificación al reportante original

**Estimación:** 3-4 horas

---

#### 4. Reportar Hallazgo
**Archivos a crear:**
- `lib/screens/reports/create_found_report_screen.dart`
- `lib/services/found_report_service.dart`

**Funcionalidades:**
- Formulario similar a avistamiento
- Énfasis en que la persona fue encontrada
- Foto recomendada
- Estado: pending (requiere confirmación)
- Notificación urgente al reportante
- Pantalla de confirmación/rechazo para el reportante

**Estimación:** 3-4 horas

---

### Prioridad 2: Sistema de Notificaciones

#### 5. Integración Firebase Cloud Messaging
**Archivos a crear/modificar:**
- `lib/services/notification_service.dart`
- `lib/main.dart` (inicialización)

**Funcionalidades:**
- Inicializar Firebase en main()
- Solicitar permisos de notificaciones
- Registrar FCM token con el backend
- Manejar notificaciones:
  - Foreground (mostrar dialog)
  - Background (mostrar en notification tray)
  - Terminated (abrir app al tap)
- Navegación al hacer tap:
  - Nueva alerta → Detalle de persona
  - Avistamiento → Detalle de persona
  - Hallazgo reportado → Confirmar/rechazar
- Local notifications para recordatorios

**Estimación:** 4-5 horas

---

#### 6. Sistema de Alertas
**Archivos a crear:**
- `lib/screens/alerts/alerts_list_screen.dart` (reemplazar tab básico)
- `lib/screens/alerts/alert_detail_screen.dart`
- `lib/services/alert_service.dart`

**Funcionalidades:**
- Lista de alertas recibidas
- Filtros: No leídas, Todas, Por distancia
- Badges con contador de no leídas
- Marcar como leída al abrir
- Registrar interacción (viewed, ignored, helpful)
- Vista de detalle con información completa
- Botón para ver en mapa
- Estadísticas de alertas

**Estimación:** 3-4 horas

---

### Prioridad 3: Mapa Interactivo

#### 7. Google Maps con Markers
**Archivos a crear:**
- `lib/screens/home/map_tab_interactive.dart` (reemplazar lista actual)
- `lib/widgets/map_marker_widget.dart`
- `lib/widgets/map_filter_widget.dart`

**Funcionalidades:**
- Google Maps centrado en ubicación actual
- Markers de personas desaparecidas:
  - Color según estado (activo, encontrado)
  - Icono personalizado con foto
  - Info window con información básica
- Clustering de markers cercanos
- Filtros en floating panel:
  - Radio de búsqueda
  - Género
  - Rango de edad
  - Días desaparecido
- Ubicación actual del usuario
- Botón para centrar en mi ubicación
- Al tap en marker → Detalle de persona

**Estimación:** 6-8 horas

---

### Prioridad 4: Perfil y Configuración

#### 8. Editar Perfil
**Archivos a crear:**
- `lib/screens/profile/edit_profile_screen.dart`
- `lib/services/user_service.dart`

**Funcionalidades:**
- Formulario con datos actuales pre-llenados
- Editar:
  - Nombre completo
  - Teléfono
  - Foto de perfil (opcional)
- Validaciones
- Guardar cambios con confirmación
- Actualizar cache local

**Estimación:** 2-3 horas

---

#### 9. Configuración de Ubicación
**Archivos a crear:**
- `lib/screens/profile/location_settings_screen.dart`

**Funcionalidades:**
- Mostrar ubicación actual en mapa
- Actualizar ubicación manualmente
- Configurar actualización automática
- Permisos de ubicación
- Radio de notificaciones (slider 1-100km)

**Estimación:** 2-3 horas

---

#### 10. Configuración General
**Archivos a crear:**
- `lib/screens/profile/settings_screen.dart`

**Funcionalidades:**
- Notificaciones push (on/off)
- Notificaciones por email (on/off)
- Radio de alertas
- Horario de notificaciones (no molestar)
- Idioma (futuro)
- Tema oscuro (futuro)

**Estimación:** 2-3 horas

---

### Prioridad 5: Mejoras UX

#### 11. Pantallas de Estados Vacíos
**Archivos a crear:**
- `lib/widgets/empty_state_widget.dart`

**Funcionalidades:**
- Estados vacíos ilustrados para:
  - Sin alertas
  - Sin reportes
  - Sin resultados de búsqueda
  - Sin conexión a internet
- Call-to-action apropiado para cada caso

**Estimación:** 1-2 horas

---

#### 12. Loading States y Skeletons
**Archivos a crear:**
- `lib/widgets/skeleton_loader.dart`

**Funcionalidades:**
- Shimmer effects para:
  - Lista de personas
  - Lista de alertas
  - Perfil de usuario
  - Detalle de persona
- Mejora percepción de velocidad

**Estimación:** 2-3 horas

---

#### 13. Compartir Reporte
**Funcionalidades:**
- Botón de compartir en detalle de persona
- Generar imagen con información
- Compartir vía:
  - WhatsApp
  - Facebook
  - Twitter
  - Instagram Stories
  - Copiar enlace
- Deep linking (abrir app desde enlace)

**Estimación:** 3-4 horas

---

### Prioridad 6: Testing y Calidad

#### 14. Testing Unitario
**Archivos a crear:**
- `test/models/` - Tests de modelos
- `test/services/` - Tests de servicios
- `test/widgets/` - Tests de widgets

**Funcionalidades:**
- Tests de modelos (toJson, fromJson)
- Tests de servicios (mock API)
- Tests de widgets clave
- Cobertura mínima 60%

**Estimación:** 4-6 horas

---

#### 15. Testing de Integración
**Archivos a crear:**
- `integration_test/app_test.dart`

**Funcionalidades:**
- Flujo completo de registro
- Flujo completo de login
- Flujo de crear reporte
- Flujo de ver alertas

**Estimación:** 3-4 horas

---

### Prioridad 7: Preparación para Producción

#### 16. Configuración de Ambientes
**Archivos a crear:**
- `lib/config/environment.dart`
- `.env.development`
- `.env.production`

**Funcionalidades:**
- Múltiples ambientes (dev, staging, prod)
- URLs de API diferentes
- Configuración de Firebase por ambiente
- Flutter flavors

**Estimación:** 2-3 horas

---

#### 17. Optimizaciones
**Tareas:**
- Optimizar imágenes (compresión)
- Cachear respuestas de API
- Implementar paginación infinita
- Optimizar build size
- Code splitting
- Analizar performance con DevTools

**Estimación:** 4-5 horas

---

#### 18. App Store Preparation
**Tareas:**
- Iconos de app (Android e iOS)
- Splash screens nativos
- Screenshots para stores
- Descripción de la app
- Privacy policy
- Terms of service
- Configurar signing (Android keystore, iOS certificates)

**Estimación:** 3-4 horas

---

## 📊 Estimación Total

| Prioridad | Tareas | Horas Estimadas |
|-----------|--------|-----------------|
| P1: Core Features | 4 tareas | 16-21 horas |
| P2: Notificaciones | 2 tareas | 7-9 horas |
| P3: Mapa | 1 tarea | 6-8 horas |
| P4: Perfil | 3 tareas | 6-9 horas |
| P5: UX | 3 tareas | 6-9 horas |
| P6: Testing | 2 tareas | 7-10 horas |
| P7: Producción | 3 tareas | 9-12 horas |
| **TOTAL** | **18 tareas** | **57-78 horas** |

**Estimación en semanas (40 hrs/semana):** 1.5 - 2 semanas

---

## 🎯 Plan de Desarrollo Sugerido

### Semana 1
**Días 1-2:**
- Crear Reporte (P1.1)
- Detalle de Persona (P1.2)

**Días 3-4:**
- Reportar Avistamiento (P1.3)
- Reportar Hallazgo (P1.4)
- Sistema de Alertas (P2.2)

**Día 5:**
- Integración FCM (P2.1)

### Semana 2
**Días 1-2:**
- Mapa Interactivo (P3.1)

**Días 3-4:**
- Editar Perfil (P4.1)
- Configuración (P4.2, P4.3)
- Mejoras UX (P5.1, P5.2, P5.3)

**Día 5:**
- Testing (P6.1, P6.2)
- Preparación producción (P7.1, P7.2, P7.3)

---

## 🛠️ Herramientas Recomendadas

### Desarrollo
- **VSCode** con extensiones:
  - Dart
  - Flutter
  - Error Lens
  - GitLens
- **Android Studio** (para emulador Android)
- **Xcode** (para emulador iOS - solo Mac)

### Testing
- **Flutter DevTools** (performance, debugging)
- **Firebase Test Lab** (testing en múltiples dispositivos)
- **BrowserStack** (testing cross-platform)

### CI/CD
- **GitHub Actions** o **Bitrise** o **Codemagic**
- Deploy automático a Firebase App Distribution
- Tests automáticos en PR

---

## 📚 Recursos de Aprendizaje

### Flutter
- [Flutter Cookbook](https://docs.flutter.dev/cookbook)
- [Flutter Codelabs](https://docs.flutter.dev/codelabs)
- [Flutter YouTube Channel](https://www.youtube.com/c/flutterdev)

### Provider
- [Provider Documentation](https://pub.dev/packages/provider)
- [State Management Guide](https://docs.flutter.dev/development/data-and-backend/state-mgmt/simple)

### Firebase
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Cloud Messaging Guide](https://firebase.flutter.dev/docs/messaging/overview)

### Google Maps
- [Google Maps Flutter Package](https://pub.dev/packages/google_maps_flutter)
- [Maps Codelabs](https://developers.google.com/codelabs/maps-platform)

---

## 🎉 Conclusión

El proyecto **BackToHome App** tiene una base sólida implementada (70% del proyecto base).

Las funcionalidades core ya están estructuradas y la arquitectura está lista para escalar.

Los próximos pasos están bien definidos y pueden ser implementados de forma incremental.

**¡El proyecto está listo para continuar el desarrollo!** 🚀

---

**BackToHome** - Ayudando a que las familias dominicanas se reencuentren 🇩🇴
