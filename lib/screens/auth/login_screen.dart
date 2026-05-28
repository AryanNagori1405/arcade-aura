import 'package:arcade_aura/screens/auth/signup_screen.dart';
import 'package:arcade_aura/services/auth_service.dart';
import 'package:arcade_aura/widgets/gradient_scaffold.dart';
import 'package:arcade_aura/widgets/neon_button.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    try {
      setState(() => _loading = true);
      await AuthService.instance.login(email: _email.text.trim(), password: _password.text.trim());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Arcade Aura', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 10),
                TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
                const SizedBox(height: 16),
                if (_loading) const CircularProgressIndicator() else NeonButton(label: 'Login', onTap: _login),
                const SizedBox(height: 10),
                NeonButton(
                  label: 'Google Sign-In',
                  onTap: () => AuthService.instance.signInWithGoogle(),
                  icon: Icons.g_mobiledata,
                  color: const Color(0xFFFF8A65),
                ),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                  child: const Text('Create account'),
                ),
                TextButton(
                  onPressed: () => AuthService.instance.forgotPassword(_email.text.trim()),
                  child: const Text('Forgot password?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
