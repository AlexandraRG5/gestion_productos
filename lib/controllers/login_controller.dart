import 'package:flutter/foundation.dart';
import '../models/login_result.dart';
import '../models/user_model.dart';
import '../services/auth_api_service.dart';
import '../services/connectivity_service.dart';

/// Controller de la vista de Login (patrón MVC).
///
/// Orquesta: 1) verificación de red, 2) llamada a POST /auth/login del
/// backend (que valida usuario y contraseña contra MySQL), 3) construcción
/// del modelo de dominio y mapeo local de rol.
/// La Vista solo debe llamar a [login] y reaccionar a [isLoading] /
/// al [LoginResult] devuelto; no conoce detalles de HTTP.
class LoginController extends ChangeNotifier {
  final AuthApiService _api;
  final ConnectivityService _connectivity;

  LoginController({
    AuthApiService? api,
    ConnectivityService? connectivity,
  })  : _api = api ?? AuthApiService(),
        _connectivity = connectivity ?? ConnectivityService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    if (username.trim().isEmpty || password.trim().isEmpty) {
      return LoginResult.unknownError('Usuario y contraseña son obligatorios.');
    }

    // Escenario 3: sin conexión, se detiene ANTES de llamar a la API.
    final online = await _connectivity.hasConnection();
    if (!online) {
      return LoginResult.noConnection();
    }

    _setLoading(true);
    try {
      // 1) Autenticación contra el backend (verifica en la base de datos).
      final data = await _api.login(username: username, password: password);

      // 2) Construcción del modelo de dominio + mapeo local de rol por id.
      final user = UserModel.fromApi(
        userJson: Map<String, dynamic>.from(data['user'] as Map),
        token: data['token'].toString(),
      );

      return LoginResult.success(user);
    } on InvalidCredentialsException {
      return LoginResult.invalidCredentials();
    } on ApiException catch (e) {
      return LoginResult.unknownError(e.message);
    } catch (e) {
      return LoginResult.unknownError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
