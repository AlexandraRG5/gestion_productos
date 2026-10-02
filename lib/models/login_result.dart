import 'user_model.dart';

/// Representa los posibles desenlaces del intento de login,
/// cubriendo los 3 escenarios de la User Story US01.
enum LoginStatus { success, invalidCredentials, noConnection, unknownError }

class LoginResult {
  final LoginStatus status;
  final UserModel? user;
  final String? message;

  LoginResult.success(UserModel user)
      : status = LoginStatus.success,
        user = user,
        message = null;

  LoginResult.invalidCredentials()
      : status = LoginStatus.invalidCredentials,
        user = null,
        message = 'Usuario o contraseña inválidos';

  LoginResult.noConnection()
      : status = LoginStatus.noConnection,
        user = null,
        message = 'No hay conexión a internet. Verifica tu red e inténtalo de nuevo.';

  LoginResult.unknownError(String detail)
      : status = LoginStatus.unknownError,
        user = null,
        message = 'Ocurrió un error inesperado: $detail';
}
