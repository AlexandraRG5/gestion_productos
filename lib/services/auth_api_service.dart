import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Capa de acceso al backend para autenticación (US01).
///
/// Responsabilidad única: hablar HTTP con POST /api/auth/login.
/// No conoce nada de UI ni de reglas de negocio (eso vive en el controller).
class AuthApiService {
  /// Autentica contra POST /auth/login.
  /// El backend verifica usuario y contraseña en MySQL y responde con
  /// `{ "token": "...", "user": { id, username, email, name, phone, role } }`.
  ///
  /// Lanza [InvalidCredentialsException] en 401/400 y [ApiException] para
  /// cualquier otro error (red o servidor).
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/login');

    late http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: ApiConfig.headers(json: true),
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw ApiException(
        'No se pudo conectar con el servidor (${ApiConfig.baseUrl}). '
        'Verifica que el backend esté encendido y que el celular esté en la misma red Wi-Fi.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      final token = body['token']?.toString();
      if (token == null || token.isEmpty || body['user'] is! Map) {
        throw ApiException('El servidor no devolvió una sesión válida.');
      }
      return body;
    }

    if (response.statusCode == 401 || response.statusCode == 400) {
      throw InvalidCredentialsException();
    }

    throw ApiException('Error del servidor (${response.statusCode}).');
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class InvalidCredentialsException implements Exception {}
