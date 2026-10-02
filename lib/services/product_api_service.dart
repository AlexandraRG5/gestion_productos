import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

/// Capa de acceso a la Fake Store API para todo lo relacionado al
/// catálogo de productos (US03) y su filtrado por categoría (US04).
///
/// Responsabilidad única: hablar HTTP con https://fakestoreapi.com.
/// No conoce nada de UI ni de reglas de negocio (eso vive en el controller).
class ProductApiService {
  static const String _baseUrl = 'https://fakestoreapi.com';

  /// GET /products — catálogo completo (US03, Escenario 1).
  Future<List<Product>> getAllProducts() => _getProductList('$_baseUrl/products');

  /// GET /products/categories — categorías disponibles (US04, Escenario 1).
  Future<List<String>> getCategories() async {
    final uri = Uri.parse('$_baseUrl/products/categories');
    final response = await _get(uri);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => e.toString()).toList();
  }

  /// GET /products/category/{category} — productos filtrados (US04, Escenario 2).
  Future<List<Product>> getProductsByCategory(String category) {
    final encoded = Uri.encodeComponent(category);
    return _getProductList('$_baseUrl/products/category/$encoded');
  }

  /// GET /products/{id} — detalle de un producto (US05, Escenarios 1 y 2).
  Future<Product> getProductById(int id) async {
    final uri = Uri.parse('$_baseUrl/products/$id');
    final response = await _get(uri);
    final Map<String, dynamic> data = jsonDecode(response.body);

    // Fake Store API responde 200 con body vacío/nulo para ids
    // inexistentes en vez de un 404 real; se trata como "no disponible"
    // (US05, Escenario 3).
    if (data.isEmpty || data['id'] == null) {
      throw ProductApiException('Producto no disponible');
    }
    return Product.fromJson(data);
  }

  /// POST /products — alta de un nuevo artículo (US06, Escenario 1).
  /// `isAdmin` se exige explícitamente: si quien llama no es
  /// Administrador, la petición se bloquea ANTES de tocar la red
  /// (regla de negocio de US06/US07/US08: "bloquea la solicitud a
  /// nivel de red/código", no solo ocultando el botón en la UI).
  Future<Product> createProduct(Map<String, dynamic> body, {required bool isAdmin}) async {
    if (!isAdmin) throw PermissionDeniedException();

    final uri = Uri.parse('$_baseUrl/products');
    late http.Response response;
    try {
      response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw ProductApiException(
        'Ocurrió un error de red. Verifica tu conexión e inténtalo de nuevo.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProductApiException('Error del servidor (${response.statusCode}).');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    return Product.fromJson(data);
  }

  /// PUT /products/{id} — edición del artículo (US05/US07, botón
  /// "Editar" funcional; solo se expone a rol Administrador).
  Future<Product> updateProduct(int id, Map<String, dynamic> body, {required bool isAdmin}) async {
    if (!isAdmin) throw PermissionDeniedException();

    final uri = Uri.parse('$_baseUrl/products/$id');
    late http.Response response;
    try {
      response = await http
          .put(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw ProductApiException(
        'Ocurrió un error de red. Verifica tu conexión e inténtalo de nuevo.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProductApiException('Error del servidor (${response.statusCode}).');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    return Product.fromJson(data);
  }

  /// DELETE /products/{id} — eliminación del artículo (US05/US08, botón
  /// "Eliminar" funcional; solo se expone a rol Administrador).
  Future<void> deleteProduct(int id, {required bool isAdmin}) async {
    if (!isAdmin) throw PermissionDeniedException();

    final uri = Uri.parse('$_baseUrl/products/$id');
    late http.Response response;
    try {
      response = await http.delete(uri).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw ProductApiException(
        'Ocurrió un error de red. Verifica tu conexión e inténtalo de nuevo.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProductApiException('Error del servidor (${response.statusCode}).');
    }
  }

  Future<List<Product>> _getProductList(String url) async {
    final response = await _get(Uri.parse(url));
    final List<dynamic> data = jsonDecode(response.body);
    return data
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<http.Response> _get(Uri uri) async {
    late http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw ProductApiException(
        'Ocurrió un error de red. Verifica tu conexión e inténtalo de nuevo.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProductApiException('Error del servidor (${response.statusCode}).');
    }

    return response;
  }
}

class ProductApiException implements Exception {
  final String message;
  ProductApiException(this.message);
  @override
  String toString() => message;
}

/// Se lanza cuando se intenta crear, editar o eliminar un producto sin
/// contar con el rol de Administrador. Representa el bloqueo "a nivel
/// de red/código" exigido por US06, US07 y US08 — la petición HTTP
/// nunca llega a construirse ni a enviarse.
class PermissionDeniedException implements Exception {
  @override
  String toString() => 'No cuentas con permisos para realizar esta acción.';
}
