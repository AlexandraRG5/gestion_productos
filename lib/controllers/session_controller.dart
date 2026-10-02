import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/secure_storage_service.dart';

/// Estado global de sesión (patrón "Controller" de MVC).
///
/// Cualquier vista puede escuchar este controller vía Provider para
/// saber si hay un usuario autenticado y con qué rol.
class SessionController extends ChangeNotifier {
  final SecureStorageService _storage;

  SessionController({SecureStorageService? storage})
      : _storage = storage ?? SecureStorageService();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  /// Intenta restaurar una sesión previa guardada en almacenamiento seguro.
  /// Útil al abrir la app (auto-login).
  Future<void> restoreSession() async {
    _currentUser = await _storage.readSession();
    notifyListeners();
  }

  /// Se llama tras un login exitoso (US01 - Escenario 1).
  Future<void> startSession(UserModel user) async {
    _currentUser = user;
    await _storage.saveSession(user);
    notifyListeners();
  }

  /// Cierre de sesión (US02).
  ///
  /// 1. Borra el token/rol del almacenamiento persistente (no solo memoria).
  /// 2. Resetea cualquier estado global relacionado al usuario (carrito, etc).
  /// La navegación (destrucción del stack de pantallas) la maneja la vista,
  /// ya que es responsabilidad de la capa de presentación, no del modelo.
  Future<void> logout() async {
    await _storage.clearSession();
    _currentUser = null;
    CartController.instance.reset();
    notifyListeners();
  }
}

/// Ejemplo de estado global adicional (carrito de compras) que la US02
/// exige resetear a cero durante el logout, para que el siguiente usuario
/// no vea productos del usuario anterior.
class CartController extends ChangeNotifier {
  CartController._();
  static final CartController instance = CartController._();

  final List<String> _items = [];
  List<String> get items => List.unmodifiable(_items);

  void addItem(String item) {
    _items.add(item);
    notifyListeners();
  }

  void reset() {
    _items.clear();
    notifyListeners();
  }
}
