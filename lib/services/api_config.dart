/// Configuración central de la conexión con TU backend (Node.js + MySQL).
///
/// ► CAMBIA LA URL de abajo según dónde corras la app:
///   - Emulador de Android ............ http://10.0.2.2:3000/api
///   - Celular físico (misma red Wi-Fi) http://<IP-de-tu-PC>:3000/api
///       (la IP la ves en la consola del backend al arrancar, o con `ipconfig`)
///
/// También puedes dejarla fuera del código al correr:
///   flutter run --dart-define=API_URL=http://192.168.1.50:3000/api
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.100.38:3000/api',
  );

  /// Token de la sesión activa. Lo asigna SessionController al iniciar o
  /// restaurar sesión y lo borra al cerrar sesión (US02).
  static String? authToken;

  static Map<String, String> headers({bool json = false}) => {
        'Accept': 'application/json',
        if (json) 'Content-Type': 'application/json',
        if (authToken != null && authToken!.isNotEmpty) 'Authorization': 'Bearer $authToken',
      };
}
