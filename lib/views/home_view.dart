import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/catalog_controller.dart';
import '../controllers/session_controller.dart';
import '../models/product.dart';
import '../models/role.dart';
import 'catalog_view.dart';
import 'login_view.dart';
import 'product_form_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final session = context.read<SessionController>();

    // US02 - Escenario 1 y 3: borra token/rol del almacenamiento
    // persistente y resetea estados globales (carrito, etc).
    await session.logout();

    if (!context.mounted) return;

    // US02 - Escenario 2: se destruye TODO el stack de pantallas
    // anteriores para que "Atrás" no regrese al catálogo/Home.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().currentUser;

    // Si por algún motivo no hay usuario (p.ej. hot-restart), evita crash.
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      // US02 - Escenario 2: bloquea el gesto/botón "Atrás" para que una
      // pantalla protegida no vuelva a mostrarse tras cerrar sesión ni
      // se pueda "saltar" el login.
      canPop: false,
      child: ChangeNotifierProvider(
        create: (_) => CatalogController()..initialize(),
        child: Scaffold(
        appBar: AppBar(
          title: const Text('Inicio'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: () => _handleLogout(context),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    child: Text(
                      user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bienvenido, ${user.username}',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Chip(
                              label: Text('Rol: ${user.role.nombre}'),
                              visualDensity: VisualDensity.compact,
                            ),
                            if (user.fullName.isNotEmpty)
                              _InfoRow(icon: Icons.badge_outlined, value: user.fullName),
                            if (user.phone.isNotEmpty)
                              _InfoRow(icon: Icons.phone_outlined, value: user.phone),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _RoleContent(role: user.role),
              ),
            ),
            const Divider(height: 1),
            // Catálogo de productos (US03) con filtro por categoría (US04),
            // ocupa el resto de la pantalla disponible.
            const Expanded(child: CatalogView()),
          ],
        ),
        // US06: botón de alta de producto, exclusivo para Administrador.
        // No se instancia en absoluto para Cliente/Auditor.
        floatingActionButton: user.role == Role.administrador
            ? Builder(
                builder: (fabContext) => FloatingActionButton.extended(
                  onPressed: () async {
                    final catalog = fabContext.read<CatalogController>();
                    await Navigator.of(fabContext).push<Product>(
                      MaterialPageRoute(builder: (_) => const ProductFormView()),
                    );
                    // El producto nuevo ya está en la base de datos: se muestra en el catálogo.
                    catalog.refresh();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo producto'),
                ),
              )
            : null,
        ),
      ),
    );
  }
}

/// Fila compacta de icono + valor, usada para mostrar datos adicionales
/// del usuario (nombre completo, teléfono) traídos de
/// la base de datos (MySQL) a través del backend.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _InfoRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

/// Interfaz distinta según el rol asignado localmente (Objetivo de US01).
class _RoleContent extends StatelessWidget {
  final Role role;
  const _RoleContent({required this.role});

  @override
  Widget build(BuildContext context) {
    switch (role) {
      case Role.administrador:
        return const Text('Panel de administración: gestión de usuarios y catálogo.');
      case Role.auditor:
        return const Text('Panel de auditoría: reportes y trazabilidad de operaciones.');
      case Role.cliente:
        return const Text('Catálogo de productos disponible para compra.');
    }
  }
}
