import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/login_controller.dart';
import '../controllers/session_controller.dart';
import '../models/login_result.dart';
import 'home_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  late final LoginController _loginController;

  @override
  void initState() {
    super.initState();
    _loginController = LoginController();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _loginController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final result = await _loginController.login(
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (!mounted) return;

    switch (result.status) {
      case LoginStatus.success:
        final session = context.read<SessionController>();
        await session.startSession(result.user!);
        if (!mounted) return;
        // US02 - al entrar, se destruye el stack previo (login no debe
        // quedar accesible con "Atrás" una vez autenticado).
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeView()),
          (route) => false,
        );
        break;

      case LoginStatus.invalidCredentials:
      case LoginStatus.noConnection:
      case LoginStatus.unknownError:
        _showErrorBanner(result.message ?? 'Error desconocido');
        break;
    }
  }

  void _showErrorBanner(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(message, style: const TextStyle(color: Colors.white)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // US02 - Escenario 2: en Login no se debe poder retroceder a vistas
    // protegidas; si estamos aquí es porque no hay sesión, así que
    // "Atrás" simplemente sale de la app.
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(title: const Text('Iniciar sesión')),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.lock_outline, size: 64),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Ingresa tu usuario' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
                    ),
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _loginController,
                      builder: (context, _) {
                        return ElevatedButton(
                          onPressed: _loginController.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                          child: _loginController.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Iniciar sesión'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
