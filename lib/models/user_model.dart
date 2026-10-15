import 'role.dart';

/// Entidad de dominio que representa al usuario autenticado.
/// Es un objeto plano (POO) sin dependencias de UI ni de red.
class UserModel {
  final int id;
  final String username;
  final String email;
  final String firstname;
  final String lastname;
  final String phone;
  final Role role;
  final String token;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstname,
    required this.lastname,
    required this.phone,
    required this.role,
    required this.token,
  });

  /// Nombre completo, listo para mostrar en la UI.
  String get fullName => [firstname, lastname]
      .where((part) => part.trim().isNotEmpty)
      .join(' ');

  /// Construye el modelo con la respuesta de POST /auth/login del backend
  /// (token + id, username, email, nombre, apellido y teléfono) y aplica
  /// la regla local de mapeo de roles por id.
  factory UserModel.fromApi({
    required Map<String, dynamic> userJson,
    required String token,
  }) {
    final int id = userJson['id'] as int;

    // El campo "name" viene anidado en el JSON del backend:
    // "name": { "firstname": "...", "lastname": "..." }
    final Map<String, dynamic> name =
        (userJson['name'] as Map<String, dynamic>?) ?? const {};

    return UserModel(
      id: id,
      username: userJson['username']?.toString() ?? '',
      email: userJson['email']?.toString() ?? '',
      firstname: name['firstname']?.toString() ?? '',
      lastname: name['lastname']?.toString() ?? '',
      phone: userJson['phone']?.toString() ?? '',
      role: RoleMapper.fromUserId(id),
      token: token,
    );
  }

  Map<String, String> toStorageMap() => {
        'id': id.toString(),
        'username': username,
        'email': email,
        'firstname': firstname,
        'lastname': lastname,
        'phone': phone,
        'role': role.toStorageValue(),
        'token': token,
      };

  factory UserModel.fromStorageMap(Map<String, String?> map) {
    return UserModel(
      id: int.tryParse(map['id'] ?? '') ?? 0,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      firstname: map['firstname'] ?? '',
      lastname: map['lastname'] ?? '',
      phone: map['phone'] ?? '',
      role: RoleMapper.fromStorageValue(map['role']),
      token: map['token'] ?? '',
    );
  }
}
