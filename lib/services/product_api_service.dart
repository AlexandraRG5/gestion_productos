import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import 'api_config.dart';

/// Capa de acceso al backend (Node.js + MySQL) para el catálogo de
/// productos (US03), su filtrado por categoría (US04), el detalle (US05)
/// y las operaciones de administración (US06, US07, US08).
///
/// Responsabilidad única: hablar HTTP con la API. No conoce nada de UI
/// ni de reglas de negocio (eso vive en el controller).
/// Todas las peticiones llevan el token de sesión (Authorization: Bearer).
class ProductApiService {
  static const Duration _timeout = Duration(seconds: 15);

  String get _products => '${ApiConfig.baseUrl}/products';

  /// GET /products — catálogo completo (US03, Escenario 1).
  Future<List<Product>> getAllProducts() => _getProductList(Uri.parse(_products));

  /// GET /products/categories — categorías disponibles (US04, Escenario 1).
  Future<List<String>> getCategories() async {
    final response = await _send(() => http.get(
          Uri.parse('$_products/categories'),
          headers: ApiConfig.headers(),
        ));
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => e.toString()).toList();
  }

  /// GET /products/category/{category} — productos filtrados (US04, Escenario 2).
  Future<List<Product>> getProductsByCategory(String category) {
    final encoded = Uri.encodeComponent(category);
    return _getProductList(Uri.parse('$_products/category/$encoded'));
  }

  /// GET /products/{id} — detalle de un producto (US05, Escenarios 1 y 2).
  /// Si el producto no existe el backend responde 404 y se lanza
  /// [ProductApiException] (US05, Escenario 3: "Producto no disponible").
  Future<Product> getProductById(int id) async {
    final response = await _send(() => http.get(
          Uri.parse('$_products/$id'),
          headers: ApiConfig.headers(),
        ));
    final Map<String, dynamic> data = jsonDecode(response.body);

    if (data.isEmpty || data['id'] == null) {
      throw ProductApiException('Producto no disponible');
    }
    return Product.fromJson(data);
  }

  /// POST /products — alta de un nuevo artículo (US06, Escenario 1).
  /// `isAdmin` se exige explícitamente: si quien llama no es
  /// Administrador, la petición se bloquea ANTES de tocar la red. Además,
  /// el backend vuelve a validar el rol con el token (responde 403).
  Future<Product> createProduct(Map<String, dynamic> body, {required bool isAdmin}) async {
    if (!isAdmin) throw PermissionDeniedException();

    final response = await _send(() => http.post(
          Uri.parse(_products),
          headers: ApiConfig.headers(json: true),
          body: jsonEncode(body),
        ));
    return Product.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// PUT /products/{id} — edición del artículo (US05/US07).
  Future<Product> updateProduct(int id, Map<String, dynamic> body, {required bool isAdmin}) async {
    if (!isAdmin) throw PermissionDeniedException();

    final response = await _send(() => http.put(
          Uri.parse('$_products/$id'),
          headers: ApiConfig.headers(json: true),
          body: jsonEncode(body),
        ));
    return Product.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// DELETE /products/{id} — eliminación del artículo (US05/US08).
  Future<void> deleteProduct(int id, {required bool isAdmin}) async {
    if (!isAdmin) throw PermissionDeniedException();

    await _send(() => http.delete(
          Uri.parse('$_products/$id'),
          headers: ApiConfig.headers(),
        ));
  }

  Future<List<Product>> _getProductList(Uri uri) async {
    final response = await _send(() => http.get(uri, headers: ApiConfig.headers()));
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Ejecuta la petición, controla timeout/red y traduce los códigos HTTP
  /// a excepciones propias que los controllers saben manejar.
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    late http.Response response;
    try {
      response = await request().timeout(_timeout);
    } catch (_) {
      throw ProductApiException(
        'No se pudo conectar con el servidor (${ApiConfig.baseUrl}). '
        'Verifica tu conexión y que el backend esté encendido.',
      );
    }

    if (response.statusCode == 401) {
      throw ProductApiException('Tu sesión expiró. Cierra sesión e inicia de nuevo.');
    }
    if (response.statusCode == 403) {
      throw PermissionDeniedException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProductApiException(_messageFrom(response));
    }
    return response;
  }

  String _messageFrom(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] != null) return body['message'].toString();
    } catch (_) {}
    return 'Error del servidor (${response.statusCode}).';
  }
}

class ProductApiException implements Exception {
  final String message;
  ProductApiException(this.message);
  @override
  String toString() => message;
}

/// Se lanza cuando se intenta crear, editar o eliminar un producto sin
/// contar con el rol de Administrador: la app bloquea la petición antes
/// de enviarla (`isAdmin`), y el backend la rechaza con 403 si llegara.
class PermissionDeniedException implements Exception {
  @override
  String toString() => 'No cuentas con permisos para realizar esta acción.';
}
