import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/product_form_controller.dart';
import '../controllers/session_controller.dart';
import '../models/product.dart';
import '../models/role.dart';

/// Formulario único reutilizado para:
/// - Crear un producto nuevo (US06) cuando [existingProduct] es null.
/// - Editar un producto existente (US07) cuando [existingProduct] no es null.
///
/// Regla de negocio compartida: el acceso se decide ESTRICTAMENTE con
/// el rol guardado en la sesión local (SessionController). Si un
/// Cliente o Auditor llega a esta pantalla por cualquier vía (enlace
/// profundo, manipulación de estado, etc.), la vista se redirige de
/// inmediato al catálogo sin construir ni mostrar el formulario
/// (US06 Escenario 3 / US07 Escenario 3).
class ProductFormView extends StatefulWidget {
  final Product? existingProduct;
  const ProductFormView({super.key, this.existingProduct});

  bool get isEditMode => existingProduct != null;

  @override
  State<ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends State<ProductFormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _imageCtrl;

  String? _selectedCategory;
  bool _redirected = false;

  @override
  void initState() {
    super.initState();
    final product = widget.existingProduct;
    _titleCtrl = TextEditingController(text: product?.title ?? '');
    _priceCtrl = TextEditingController(text: product != null ? product.price.toStringAsFixed(2) : '');
    _descriptionCtrl = TextEditingController(text: product?.description ?? '');
    _imageCtrl = TextEditingController(text: product?.image ?? '');
    _selectedCategory = product?.category;

    // Control de acceso: se verifica ANTES de que el usuario pueda ver
    // o interactuar con el formulario.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = context.read<SessionController>().currentUser?.role;
      if (role != Role.administrador) {
        _redirectUnauthorized();
        return;
      }
      context.read<ProductFormController>().loadCategories();
    });
  }

  void _redirectUnauthorized() {
    if (_redirected || !mounted) return;
    _redirected = true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No tienes permisos para acceder a esta pantalla.')),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _descriptionCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<SessionController>().currentUser?.role;

    // Mientras se resuelve la redirección (o si por algún motivo se
    // reconstruye con un rol no autorizado), no se instancia NADA del
    // formulario: ni los campos ni los botones de guardado.
    if (role != Role.administrador) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return ChangeNotifierProvider(
      create: (_) => ProductFormController()..loadCategories(),
      child: _ProductFormBody(
        formKey: _formKey,
        titleCtrl: _titleCtrl,
        priceCtrl: _priceCtrl,
        descriptionCtrl: _descriptionCtrl,
        imageCtrl: _imageCtrl,
        selectedCategory: _selectedCategory,
        onCategoryChanged: (value) => setState(() => _selectedCategory = value),
        existingProduct: widget.existingProduct,
      ),
    );
  }
}

class _ProductFormBody extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController descriptionCtrl;
  final TextEditingController imageCtrl;
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final Product? existingProduct;

  const _ProductFormBody({
    required this.formKey,
    required this.titleCtrl,
    required this.priceCtrl,
    required this.descriptionCtrl,
    required this.imageCtrl,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.existingProduct,
  });

  bool get isEditMode => existingProduct != null;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProductFormController>();

    return Scaffold(
      appBar: AppBar(title: Text(isEditMode ? 'Editar producto' : 'Nuevo producto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Título', border: OutlineInputBorder()),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'El título es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceCtrl,
                decoration: const InputDecoration(labelText: 'Precio', border: OutlineInputBorder(), prefixText: '\$ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                validator: _validatePrice,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descriptionCtrl,
                decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                maxLines: 4,
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'La descripción es obligatoria' : null,
              ),
              const SizedBox(height: 16),
              if (!isEditMode) ...[
                TextFormField(
                  controller: imageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL de la imagen',
                    hintText: 'https://ejemplo.com/imagen.jpg',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.url,
                  validator: _validateImageUrl,
                ),
                const SizedBox(height: 16),
              ],
              _CategoryField(
                controller: controller,
                selectedCategory: selectedCategory,
                onChanged: onCategoryChanged,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  // Deshabilitado mientras la solicitud está en curso,
                  // evitando envíos duplicados (nota de US07).
                  onPressed: controller.isSaving
                      ? null
                      : () => _submit(context, controller),
                  child: controller.isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isEditMode ? 'Guardar cambios' : 'Guardar producto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) return 'El precio es obligatorio';
    final normalized = value.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null) return 'Ingresa un precio numérico válido';
    if (parsed <= 0) return 'El precio debe ser mayor a cero';
    return null;
  }

  String? _validateImageUrl(String? value) {
    if (value == null || value.trim().isEmpty) return 'La URL de la imagen es obligatoria';
    final uri = Uri.tryParse(value.trim());
    final isValid = uri != null &&
        uri.hasAbsolutePath &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return isValid ? null : 'Ingresa una URL válida (http:// o https://)';
  }

  Future<void> _submit(BuildContext context, ProductFormController controller) async {
    // US06/US07 - Escenario 2: si hay campos inválidos, se detiene la
    // petición y Flutter resalta en rojo los campos correspondientes.
    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid || selectedCategory == null) {
      if (selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona una categoría.')),
        );
      }
      return;
    }

    // Defensa adicional: se vuelve a leer el rol local justo antes de
    // disparar la petición (US06/US07, Escenario 3).
    final isAdmin = context.read<SessionController>().currentUser?.role == Role.administrador;
    final price = double.parse(priceCtrl.text.trim().replaceAll(',', '.'));

    if (isEditMode) {
      final updated = await controller.updateProduct(
        isAdmin: isAdmin,
        id: existingProduct!.id,
        title: titleCtrl.text.trim(),
        price: price,
        description: descriptionCtrl.text.trim(),
        image: existingProduct!.image,
        category: selectedCategory!,
      );

      if (!context.mounted) return;
      if (updated != null) {
        // US07 - Escenario 1: mensaje exacto + cierre del formulario,
        // reflejando el cambio en la pantalla de detalle (vía pop con
        // el producto actualizado).
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto actualizado (Simulación)')),
        );
        Navigator.of(context).pop(updated);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar el producto.')),
        );
      }
    } else {
      final created = await controller.createProduct(
        isAdmin: isAdmin,
        title: titleCtrl.text.trim(),
        price: price,
        description: descriptionCtrl.text.trim(),
        image: imageCtrl.text.trim(),
        category: selectedCategory!,
      );

      if (!context.mounted) return;
      if (created != null) {
        // US06 - Escenario 1: alerta de confirmación con el nuevo ID
        // y limpieza del formulario (permanece en la pantalla).
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Producto creado'),
            content: Text(
              'Se generó el producto con ID #${created.id} (simulación: '
              'no se guardó realmente en el servidor ni aparecerá en el '
              'catálogo general).',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );
        titleCtrl.clear();
        priceCtrl.clear();
        descriptionCtrl.clear();
        imageCtrl.clear();
        onCategoryChanged(null);
        formKey.currentState?.reset();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo crear el producto.')),
        );
      }
    }
  }
}

class _CategoryField extends StatelessWidget {
  final ProductFormController controller;
  final String? selectedCategory;
  final ValueChanged<String?> onChanged;

  const _CategoryField({
    required this.controller,
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.categoriesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }

    if (controller.categories.isEmpty) {
      return const Text(
        'No fue posible cargar las categorías disponibles. Verifica tu conexión.',
        style: TextStyle(color: Colors.red),
      );
    }

    final value = controller.categories.contains(selectedCategory) ? selectedCategory : null;

    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
      items: controller.categories
          .map((c) => DropdownMenuItem(value: c, child: Text(_capitalize(c))))
          .toList(),
      onChanged: onChanged,
      validator: (_) => value == null ? 'Selecciona una categoría' : null,
    );
  }

  String _capitalize(String text) =>
      text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';
}
