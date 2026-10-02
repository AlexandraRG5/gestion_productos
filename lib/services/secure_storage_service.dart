import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

/// Envuelve flutter_secure_storage (Keychain en iOS, EncryptedSharedPreferences
/// / KeyStore en Android) para persistir y borrar la sesión del usuario.
///
/// Esta clase es la única responsable de tocar el almacenamiento persistente,
/// cumpliendo con la regla de negocio de US01 ("almacenamiento seguro nativo")
/// y con la limpieza profunda exigida por US02.
class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kId = 'session_id';
  static const _kUsername = 'session_username';
  static const _kEmail = 'session_email';
  static const _kFirstname = 'session_firstname';
  static const _kLastname = 'session_lastname';
  static const _kPhone = 'session_phone';
  static const _kRole = 'session_role';
  static const _kToken = 'session_token';

  Future<void> saveSession(UserModel user) async {
    final map = user.toStorageMap();
    await Future.wait([
      _storage.write(key: _kId, value: map['id']),
      _storage.write(key: _kUsername, value: map['username']),
      _storage.write(key: _kEmail, value: map['email']),
      _storage.write(key: _kFirstname, value: map['firstname']),
      _storage.write(key: _kLastname, value: map['lastname']),
      _storage.write(key: _kPhone, value: map['phone']),
      _storage.write(key: _kRole, value: map['role']),
      _storage.write(key: _kToken, value: map['token']),
    ]);
  }

  Future<UserModel?> readSession() async {
    final token = await _storage.read(key: _kToken);
    if (token == null || token.isEmpty) return null;
    return UserModel.fromStorageMap({
      'id': await _storage.read(key: _kId),
      'username': await _storage.read(key: _kUsername),
      'email': await _storage.read(key: _kEmail),
      'firstname': await _storage.read(key: _kFirstname),
      'lastname': await _storage.read(key: _kLastname),
      'phone': await _storage.read(key: _kPhone),
      'role': await _storage.read(key: _kRole),
      'token': token,
    });
  }

  /// Limpieza profunda exigida por US02: borra TODAS las claves de sesión
  /// del almacenamiento persistente del dispositivo, no solo variables
  /// en memoria.
  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _kId),
      _storage.delete(key: _kUsername),
      _storage.delete(key: _kEmail),
      _storage.delete(key: _kFirstname),
      _storage.delete(key: _kLastname),
      _storage.delete(key: _kPhone),
      _storage.delete(key: _kRole),
      _storage.delete(key: _kToken),
    ]);
  }
}
