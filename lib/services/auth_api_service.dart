import 'dart:convert';
import 'package:http/http.dart' as http;

/// Capa de acceso a la Fake Store API.
///
/// Responsabilidad única: hablar HTTP con https://fakestoreapi.com.
/// No conoce nada de UI ni de reglas de negocio (eso vive en el controller).
class AuthApiService {
  static const String _baseUrl = 'https://fakestoreapi.com';

  /// Autentica contra POST /auth/login.
  /// Devuelve el token si la API responde 200 OK.
  /// Lanza [InvalidCredentialsException] en 401 (o similar) y
  /// [ApiException] para cualquier otro error HTTP.
  Future<String> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      final token = body['token']?.toString();
      if (token == null || token.isEmpty) {
        throw ApiException('La API no devolvió un token válido.');
      }
      return token;
    }

    if (response.statusCode == 401 || response.statusCode == 400) {
      throw InvalidCredentialsException();
    }

    throw ApiException('Error del servidor (${response.statusCode}).');
  }

  /// Verifica los datos ingresados contra GET /users, tal como pide el
  /// requerimiento: se descarga la lista de usuarios de
  /// https://fakestoreapi.com/users y se busca el registro cuyo
  /// username coincide (comparación case-insensitive), para así obtener
  /// el ID real con el que se hace el mapeo local de roles.
  Future<Map<String, dynamic>> findUserByUsername(String username) async {
    final uri = Uri.parse('$_baseUrl/users');
    final response = await http.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('No se pudo obtener la lista de usuarios (${response.statusCode}).');
    }

    final List<dynamic> users = jsonDecode(response.body);
    final match = users.firstWhere(
      (u) => (u['username']?.toString().toLowerCase() ?? '') ==
          username.toLowerCase(),
      orElse: () => null,
    );

    if (match == null) {
      // El usuario no existe en la base de Fake Store API.
      throw InvalidCredentialsException();
    }

    return Map<String, dynamic>.from(match);
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class InvalidCredentialsException implements Exception {}
