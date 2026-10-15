import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/product_api_service.dart';

/// Controlador de la vista de detalle de producto (US05).
///
/// No conoce nada sobre roles: la decisión de qué controles mostrar
/// (Editar/Eliminar) vive en la Vista, que lee el rol directamente de
/// la sesión local (SessionController), tal como exige la regla de
/// negocio de US05 ("no delegar la validación a la API").
/// Aun así, `delete()` exige explícitamente `isAdmin` como defensa
/// adicional a nivel de código (US08, Escenario 3).
class ProductDetailController extends ChangeNotifier {
  final ProductApiService _api;

  ProductDetailController({ProductApiService? api}) : _api = api ?? ProductApiService();

  Product? _product;
  Product? get product => _product;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  /// true si la carga falló o el producto no existe (US05, Escenario 3).
  bool _notAvailable = false;
  bool get notAvailable => _notAvailable;

  bool _isDeleting = false;
  bool get isDeleting => _isDeleting;

  Future<void> load(int id) async {
    _isLoading = true;
    _notAvailable = false;
    notifyListeners();

    try {
      _product = await _api.getProductById(id);
    } catch (_) {
      _product = null;
      _notAvailable = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reemplaza el producto mostrado con la versión devuelta por la
  /// pantalla de edición (US07, Escenario 1: "refleja los cambios
  /// visualmente en la pantalla de detalle"), sin disparar una nueva
  /// petición de red.
  void setProduct(Product updated) {
    _product = updated;
    notifyListeners();
  }

  /// Eliminación funcional del artículo (US08, Escenario 1).
  /// `isAdmin` se exige explícitamente: si no es Administrador, la
  /// petición DELETE jamás se construye (US08, Escenario 3).
  /// Devuelve true si la eliminación fue exitosa.
  Future<bool> delete({required bool isAdmin}) async {
    if (_product == null) return false;

    _isDeleting = true;
    notifyListeners();

    try {
      await _api.deleteProduct(_product!.id, isAdmin: isAdmin);
      return true;
    } catch (_) {
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }
}
