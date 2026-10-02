import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/session_controller.dart';
import 'views/login_view.dart';
import 'views/home_view.dart';

void main() {
  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionController()..restoreSession()),
      ],
      child: MaterialApp(
        title: 'Login App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const _AppGate(),
      ),
    );
  }
}

/// Decide, tras el arranque, si mostrar Login o Home según si existe
/// una sesión persistida en almacenamiento seguro (auto-login).
class _AppGate extends StatelessWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    return session.isAuthenticated ? const HomeView() : const LoginView();
  }
}
