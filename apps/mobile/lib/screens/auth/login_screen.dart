import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/theme.dart';
import '../../providers/finance_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      if (mounted) {
        await ref.read(financeProvider.notifier).fetchAll();
        context.go('/dashboard');
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: kRed),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
  setState(() => _loading = true);
  try {
    await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'com.blacksong.flujo://login-callback',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  } on AuthException catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: kRed),
      );
    }
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // Logo
              Center(
                child: Column(children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      color: kBrand.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.trending_up_rounded, color: kBrand, size: 30),
                  ),
                  const SizedBox(height: 14),
                  const Text('FLUJO', style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w800,
                    color: kBrand, letterSpacing: -1,
                  )),
                  const Text('Finance OS', style: TextStyle(
                    fontSize: 11, color: kMuted, letterSpacing: 3,
                  )),
                ]),
              ),
              const SizedBox(height: 52),
              const Text('Iniciar sesión', style: kHeading),
              const SizedBox(height: 4),
              const Text('Accede a tu dashboard financiero',
                style: TextStyle(color: kMuted, fontSize: 14)),
              const SizedBox(height: 28),
              // Email
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: kText),
                decoration: const InputDecoration(labelText: 'Correo electrónico'),
              ),
              const SizedBox(height: 16),
              // Password
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: kText),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: kMuted, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Botón login
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Iniciar sesión'),
                ),
              ),
              const SizedBox(height: 16),
              // Divider
              Row(children: [
                const Expanded(child: Divider(color: Color(0xFF2A2D3E))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('o continúa con',
                    style: TextStyle(color: kMuted, fontSize: 12)),
                ),
                const Expanded(child: Divider(color: Color(0xFF2A2D3E))),
              ]),
              const SizedBox(height: 16),
              // Botón Google
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _loginWithGoogle,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF2A2D3E)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Text('G', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: Colors.white)),
                  label: const Text('Continuar con Google',
                    style: TextStyle(color: Colors.white, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 24),
              // Registro
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('¿No tienes cuenta? ',
                    style: TextStyle(color: kMuted)),
                  GestureDetector(
                    onTap: () => context.go('/auth/register'),
                    child: const Text('Regístrate',
                      style: TextStyle(color: kBrand, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }
}