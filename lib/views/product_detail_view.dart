import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/product_detail_controller.dart';
import '../controllers/session_controller.dart';
import '../models/product.dart';
import '../models/role.dart';
import 'product_form_view.dart';

/// Vista de detalle de un producto (US05).
///
/// - Escenario 1: Cliente/Auditor ven imagen, título, precio,
///   descripción y categoría, sin controles de edición/eliminación.
/// - Escenario 2: Administrador ve además los botones "Editar" y
///   "Eliminar", funcionales contra la API.
/// - Escenario 3: si la consulta falla o el producto no existe, se
///   muestra una alerta "Producto no disponible" y se regresa
///   automáticamente al catálogo.
///
/// Regla de negocio: el rol se lee ESTRICTAMENTE de la sesión local
/// (SessionController), nunca de la API. Los botones de
/// gestión no se instancian en absoluto si el rol no es Administrador
/// (no se ocultan con Visibility/Opacity).
class ProductDetailView extends StatelessWidget {
  final int productId;
  const ProductDetailView({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductDetailController()..load(productId),
      child: const _ProductDetailBody(),
    );
  }
}

class _ProductDetailBody extends StatefulWidget {
  const _ProductDetailBody();

  @override
  State<_ProductDetailBody> createState() => _ProductDetailBodyState();
}

class _ProductDetailBodyState extends State<_ProductDetailBody> {
  bool _errorDialogShown = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProductDetailController>();

    // Escenario 3: alerta + regreso automático al catálogo.
    if (controller.notAvailable && !_errorDialogShown) {
      _errorDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showNotAvailableDialog(context));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : controller.product == null
              ? const SizedBox.shrink() // El diálogo de error ya se está mostrando.
              : _ProductDetailContent(product: controller.product!),
    );
  }

  Future<void> _showNotAvailableDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Producto no disponible'),
        content: const Text(
          'No fue posible obtener la información de este producto. '
          'Es posible que ya no exista o que haya un problema de conexión.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    // Retorno automático a la pantalla del catálogo.
    Navigator.of(context).pop();
  }
}

class _ProductDetailContent extends StatelessWidget {
  final Product product;
  const _ProductDetailContent({required this.product});

  @override
  Widget build(BuildContext context) {
    // Regla de negocio de US05: el rol se lee de la sesión local, nunca
    // de la API.
    final role = context.watch<SessionController>().currentUser?.role;
    final isAdmin = role == Role.administrador;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: CachedNetworkImage(
              imageUrl: product.image,
              height: 220,
              fit: BoxFit.contain,
              placeholder: (context, url) =>
                  const SizedBox(height: 220, child: Center(child: CircularProgressIndicator())),
              errorWidget: (context, url, error) => const SizedBox(
                height: 220,
                child: Icon(Icons.broken_image_outlined, size: 64, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(product.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Chip(label: Text(product.category)),
          const SizedBox(height: 12),
          Text(
            '\$${product.price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(product.description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 28),

          // Escenario 2: estos botones NO se instancian en absoluto si el
          // rol no es Administrador (no Visibility/Opacity).
          if (isAdmin) const _AdminActions(),
        ],
      ),
    );
  }
}

class _AdminActions extends StatelessWidget {
  const _AdminActions();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProductDetailController>();

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: controller.isDeleting ? null : () => _openEditScreen(context),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: controller.isDeleting ? null : () => _confirmDelete(context),
            icon: controller.isDeleting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.delete_outline),
            label: const Text('Eliminar'),
          ),
        ),
      ],
    );
  }

  // US07: abre la pantalla de edición (formulario pre-cargado) y, si
  // vuelve con un producto actualizado, refresca el detalle sin volver
  // a llamar a la API.
  Future<void> _openEditScreen(BuildContext context) async {
    final detailController = context.read<ProductDetailController>();
    final product = detailController.product!;

    final updated = await Navigator.of(context).push<Product>(
      MaterialPageRoute(builder: (_) => ProductFormView(existingProduct: product)),
    );

    if (updated != null) {
      detailController.setProduct(updated);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final controller = context.read<ProductDetailController>();

    // US08 - Escenario 2: confirmación obligatoria antes de cualquier
    // petición destructiva.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: const Text('¿Estás seguro de eliminar este producto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    // Cancelar: no se realiza ninguna petición de red, la vista no cambia.
    if (confirmed != true) return;

    // Defensa adicional a nivel de código (US08, Escenario 3): se
    // vuelve a leer el rol local justo antes de la petición DELETE.
    final isAdmin = context.read<SessionController>().currentUser?.role == Role.administrador;
    final success = await controller.delete(isAdmin: isAdmin);

    if (!context.mounted) return;

    // Se captura el messenger del catálogo ANTES de hacer pop, para
    // que el mensaje flotante se muestre correctamente en esa pantalla.
    final catalogMessenger = ScaffoldMessenger.of(context);

    if (success) {
      Navigator.of(context).pop(); // US08 - Escenario 1: regresa al catálogo.
      catalogMessenger.showSnackBar(
        const SnackBar(content: Text('Producto eliminado.')),
      );
    } else {
      catalogMessenger.showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar el producto.')),
      );
    }
  }
}
