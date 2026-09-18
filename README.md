# Login App (Flutter) — US01 / US02

Aplicación Flutter que implementa:

- **US01** — Login contra `POST https://fakestoreapi.com/auth/login`, verificación
  del usuario contra `GET https://fakestoreapi.com/users` y asignación local
  de rol (id 1-2 → Administrador, id 3 → Auditor, resto → Cliente).
- **US02** — Cierre de sesión con limpieza profunda de credenciales
  (almacenamiento seguro), destrucción del stack de navegación y reinicio
  de estados globales (carrito).

## Arquitectura (MVC + POO)

```
lib/
  models/        -> Model: entidades de dominio (UserModel, Role, LoginResult)
  services/       -> acceso a datos: HTTP (AuthApiService), almacenamiento
                     seguro (SecureStorageService), conectividad
  controllers/    -> Controller: lógica de negocio y estado (LoginController,
                     SessionController) — no conocen widgets de Flutter
  views/          -> View: pantallas (LoginView, HomeView) — solo UI,
                     delegan toda la lógica a los controllers
```

- **Model**: `UserModel`, `Role`, `LoginResult` — clases planas, sin dependencias externas.
- **View**: `LoginView`, `HomeView` — widgets que muestran estado y capturan input.
- **Controller**: `LoginController`, `SessionController` — `ChangeNotifier`
  que orquestan servicios y exponen estado observable a las vistas (patrón
  Observer, vía `provider`).

## Cómo ejecutar

Este entorno no tiene el SDK de Flutter instalado, así que el proyecto se
entrega como código fuente (`lib/` + `pubspec.yaml`). Para correrlo:

```bash
flutter create login_app_flutter        # genera android/ ios/ etc.
cd login_app_flutter
# reemplaza el lib/ y pubspec.yaml generados por los de este ZIP
flutter pub get
flutter run
```

### Permisos necesarios

En `android/app/src/main/AndroidManifest.xml`, agrega dentro de `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### Credenciales de prueba

Fake Store API expone usuarios de prueba en `GET /users`. Usa el
`username`/`password` de cualquiera de esos registros (por ejemplo el
usuario con `id: 1` iniciará como Administrador).

## Escenarios cubiertos

| US | Escenario | Dónde |
|---|---|---|
| US01 | Login exitoso + mapeo de rol | `LoginController.login()` + `RoleMapper.fromUserId` |
| US01 | Credenciales incorrectas → alerta roja | `LoginView._showErrorBanner` |
| US01 | Sin conexión → detiene antes de llamar API | `ConnectivityService` + `LoginController` |
| US02 | Logout borra credenciales | `SecureStorageService.clearSession` |
| US02 | Bloqueo de "Atrás" tras logout / en Home | `PopScope` en `LoginView` y `HomeView` + `pushAndRemoveUntil` |
| US02 | Reinicio de estado global (carrito) | `CartController.reset()` en `SessionController.logout()` |
