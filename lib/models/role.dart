/// Roles soportados por la aplicación.
///
/// Regla de negocio (US01):
///  - id 1 y 2  -> Administrador
///  - id 3      -> Auditor
///  - resto     -> Cliente
enum Role { administrador, auditor, cliente }

extension RoleMapper on Role {
  String get nombre {
    switch (this) {
      case Role.administrador:
        return 'Administrador';
      case Role.auditor:
        return 'Auditor';
      case Role.cliente:
        return 'Cliente';
    }
  }

  /// Asigna el rol de forma local en base al ID numérico del usuario
  /// devuelto por la API. Esta es la única fuente de verdad
  /// para el mapeo de roles (regla de negocio de US01).
  static Role fromUserId(int id) {
    if (id == 1 || id == 2) return Role.administrador;
    if (id == 3) return Role.auditor;
    return Role.cliente;
  }

  /// Serializa el rol para poder persistirlo en almacenamiento seguro.
  String toStorageValue() => name;

  static Role fromStorageValue(String? value) {
    return Role.values.firstWhere(
      (r) => r.name == value,
      orElse: () => Role.cliente,
    );
  }
}
