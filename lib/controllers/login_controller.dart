import 'package:flutter/foundation.dart';
import '../models/login_result.dart';
import '../models/user_model.dart';
import '../services/auth_api_service.dart';
import '../services/connectivity_service.dart';

/// Controller de la vista de Login (patrón MVC).
///
/// Orquesta: 1) verificación de red, 2) llamada a /auth/login,
/// 3) verificación del usuario contra /users, 4) mapeo local de rol.
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
      // 1) Autenticación real contra /auth/login
      final token = await _api.login(username: username, password: password);

      // 2) Verificación/descarga de datos del usuario contra /users
      final userJson = await _api.findUserByUsername(username);

      // 3) Mapeo local de rol + construcción del modelo de dominio
      final user = UserModel.fromApi(userJson: userJson, token: token);

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
