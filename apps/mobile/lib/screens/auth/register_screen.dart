import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    if (_passwordCtrl.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña debe tener al menos 8 caracteres'), backgroundColor: kRed),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        data: {'full_name': _nameCtrl.text.trim()},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Cuenta creada! Revisa tu correo.'), backgroundColor: kBrand),
        );
        context.go('/auth/login');
      }
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: kRed),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded, size: 18),
          onPressed: () => context.go('/auth/login'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Empieza gratis', style: kHeading),
            const SizedBox(height: 4),
            const Text('Controla tus finanzas desde hoy', style: TextStyle(color: kMuted)),
            const SizedBox(height: 28),
            TextField(controller: _nameCtrl, style: const TextStyle(color: kText),
              decoration: const InputDecoration(labelText: 'Nombre completo')),
            const SizedBox(height: 14),
            TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: kText),
              decoration: const InputDecoration(labelText: 'Correo electrónico')),
            const SizedBox(height: 14),
            TextField(controller: _passwordCtrl, obscureText: true,
              style: const TextStyle(color: kText),
              decoration: const InputDecoration(labelText: 'Contraseña (mín. 8 caracteres)')),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Crear cuenta gratis'),
              )),
          ],
        ),
      ),
    );
  }
}
