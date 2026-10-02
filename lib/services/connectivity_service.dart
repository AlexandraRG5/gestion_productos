import 'package:connectivity_plus/connectivity_plus.dart';

/// Encapsula la verificación de red. Antes de consumir la API,
/// el controlador debe preguntar aquí si hay conexión (US01 - Escenario 3).
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> hasConnection() async {
    final result = await _connectivity.checkConnectivity();
    // connectivity_plus >= 6 devuelve List<ConnectivityResult>
    return result.isNotEmpty && !result.contains(ConnectivityResult.none);
  }
}
