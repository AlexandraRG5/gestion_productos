import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/catalog_controller.dart';
import '../models/product.dart';
import 'product_detail_view.dart';

/// Vista del catálogo de productos.
///
/// - US03: lista reciclable (ListView.builder) con imagen, título y
///   precio de cada producto; estados de loading y error con "Reintentar".
/// - US04: fila de chips deslizable con las categorías disponibles
///   (incluye "Todas" para remover el filtro), que dispara el filtrado
///   sin bloquear la visibilidad del resto de la pantalla.
class CatalogView extends StatelessWidget {
  const CatalogView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CatalogController()..initialize(),
      child: const _CatalogBody(),
    );
  }
}

class _CatalogBody extends StatelessWidget {
  const _CatalogBody();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CatalogController>();

    return Column(
      children: [
        if (controller.categories.isNotEmpty) const _CategoryChips(),
        Expanded(child: _CatalogContent(controller: controller)),
      ],
    );
  }
}

/// Componente visual accesible para filtrar (chips deslizables), tal
/// como lo piden las notas de US04, sin bloquear la visibilidad del
/// catálogo debajo.
class _CategoryChips extends StatelessWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CatalogController>();

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: const Text('Todas'),
              selected: !controller.hasActiveFilter,
              onSelected: (_) => controller.loadAllProducts(),
            ),
          ),
          ...controller.categories.map(
            (category) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(_capitalize(category)),
                selected: controller.selectedCategory == category,
                onSelected: (_) => controller.filterByCategory(category),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String text) =>
      text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';
}

class _CatalogContent extends StatelessWidget {
  final CatalogController controller;
  const _CatalogContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    // Escenario 2 de US03 / Consistencia de carga de US04: mismo
    // spinner centrado para cualquier cambio de categoría o carga inicial.
    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Escenario 3 de US03: mensaje amigable + botón "Reintentar".
    if (controller.errorMessage != null) {
      return _ErrorState(
        message: controller.errorMessage!,
        onRetry: () => controller.retry(),
      );
    }

    if (controller.products.isEmpty) {
      return const Center(child: Text('No hay productos para mostrar.'));
    }

    // Lista reciclable (ListView.builder): no renderiza todos los
    // elementos de golpe, evitando problemas de memoria en listas largas.
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: controller.products.length,
      itemBuilder: (context, index) => _ProductCard(product: controller.products[index]),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ProductDetailView(productId: product.id)),
        ),
        child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              // Descarga asíncrona en segundo plano + caché en disco,
              // sin congelar la interfaz (regla de negocio de US03).
              child: CachedNetworkImage(
                imageUrl: product.image,
                width: 72,
                height: 72,
                fit: BoxFit.contain,
                placeholder: (context, url) => const SizedBox(
                  width: 72,
                  height: 72,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => const SizedBox(
                  width: 72,
                  height: 72,
                  child: Icon(Icons.broken_image_outlined, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
