import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/product_api_service.dart';

/// Controlador compartido por el formulario de creación (US06) y el
/// de edición (US07) de productos.
///
/// Ambas operaciones exigen `isAdmin` explícitamente: si quien llama
/// no es Administrador, el controlador nunca llega a invocar la capa
/// de red (US06/US07, Escenario 3: "bloquea la solicitud a nivel de
/// red").
class ProductFormController extends ChangeNotifier {
  final ProductApiService _api;

  ProductFormController({ProductApiService? api}) : _api = api ?? ProductApiService();

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  List<String> _categories = [];
  List<String> get categories => List.unmodifiable(_categories);

  bool _categoriesLoading = false;
  bool get categoriesLoading => _categoriesLoading;

  Future<void> loadCategories() async {
    _categoriesLoading = true;
    notifyListeners();
    try {
      _categories = await _api.getCategories();
    } catch (_) {
      _categories = [];
    } finally {
      _categoriesLoading = false;
      notifyListeners();
    }
  }

  /// US06 - Escenario 1: alta de un nuevo artículo.
  /// Devuelve el producto creado (con el nuevo ID que simula la API)
  /// o null si la operación fue bloqueada o falló.
  Future<Product?> createProduct({
    required bool isAdmin,
    required String title,
    required double price,
    required String description,
    required String image,
    required String category,
  }) async {
    _isSaving = true;
    notifyListeners();

    try {
      return await _api.createProduct({
        'title': title,
        'price': price,
        'description': description,
        'image': image,
        'category': category,
      }, isAdmin: isAdmin);
    } catch (_) {
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// US07 - Escenario 1: edición de un artículo existente.
  /// Devuelve el producto actualizado o null si fue bloqueado o falló.
  Future<Product?> updateProduct({
    required bool isAdmin,
    required int id,
    required String title,
    required double price,
    required String description,
    required String image,
    required String category,
  }) async {
    _isSaving = true;
    notifyListeners();

    try {
      return await _api.updateProduct(id, {
        'title': title,
        'price': price,
        'description': description,
        'image': image,
        'category': category,
      }, isAdmin: isAdmin);
    } catch (_) {
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
