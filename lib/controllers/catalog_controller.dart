import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/product_api_service.dart';

/// Controlador del catálogo de productos (patrón "Controller" de MVC).
///
/// Cubre:
/// - US03: carga inicial del catálogo completo, con estados de
///   loading y error con reintento.
/// - US04: obtención de categorías, aplicación y remoción del filtro,
///   incluyendo la limpieza del arreglo anterior antes de cada nueva
///   petición para evitar mostrar datos incorrectos ("Gestión de
///   memoria" en las notas de US04).
class CatalogController extends ChangeNotifier {
  final ProductApiService _api;

  CatalogController({ProductApiService? api}) : _api = api ?? ProductApiService();

  List<Product> _products = [];
  List<Product> get products => List.unmodifiable(_products);

  List<String> _categories = [];
  List<String> get categories => List.unmodifiable(_categories);

  /// null = sin filtro (catálogo general / "Ver todos").
  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;
  bool get hasActiveFilter => _selectedCategory != null;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Punto de entrada al inicializar la vista del catálogo.
  /// Carga las categorías disponibles (US04 - Escenario 1) y el
  /// catálogo general (US03 - Escenario 1).
  Future<void> initialize() async {
    await Future.wait([
      _loadCategories(),
      loadAllProducts(),
    ]);
  }

  Future<void> _loadCategories() async {
    try {
      _categories = await _api.getCategories();
      notifyListeners();
    } catch (_) {
      // Si fallan las categorías, el catálogo general igual puede
      // mostrarse; simplemente no habrá chips de filtro disponibles.
      _categories = [];
      notifyListeners();
    }
  }

  /// US03 - Escenarios 1, 2 y 3 / US04 - Escenario 3 (remoción del filtro).
  Future<void> loadAllProducts() async {
    _selectedCategory = null;
    await _fetch(() => _api.getAllProducts());
  }

  /// US04 - Escenario 2: aplica el filtro por categoría.
  Future<void> filterByCategory(String category) async {
    _selectedCategory = category;
    await _fetch(() => _api.getProductsByCategory(category));
  }

  /// Reintenta la última petición fallida (catálogo general o filtrada),
  /// según el botón "Reintentar" del Escenario 3 de US03.
  Future<void> retry() async {
    if (_selectedCategory != null) {
      await filterByCategory(_selectedCategory!);
    } else {
      await loadAllProducts();
    }
  }

  /// Recarga en silencio (sin spinner ni vaciar la lista) el catálogo y las
  /// categorías. Se usa al volver del detalle/formulario, porque ahora los
  /// cambios (crear, editar, eliminar) son reales y deben verse en la lista.
  Future<void> refresh() async {
    try {
      final result = _selectedCategory != null
          ? await _api.getProductsByCategory(_selectedCategory!)
          : await _api.getAllProducts();
      _products = result;
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      // Si falla, se conserva la lista actual sin molestar al usuario.
    }
    await _loadCategories();
  }

  Future<void> _fetch(Future<List<Product>> Function() request) async {
    // Gestión de memoria (US04): se limpia el arreglo anterior ANTES de
    // lanzar la nueva petición, para que la vista nunca muestre datos
    // de la categoría/estado previo mientras la nueva carga finaliza.
    _products = [];
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      final result = await request();
      _products = result;
      _errorMessage = null;
    } on ProductApiException catch (e) {
      _products = [];
      _errorMessage = e.message;
    } catch (e) {
      _products = [];
      _errorMessage = 'Ocurrió un error inesperado al cargar los productos.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
