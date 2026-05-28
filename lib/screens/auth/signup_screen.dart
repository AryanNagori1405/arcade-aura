import 'package:arcade_aura/services/auth_service.dart';
import 'package:arcade_aura/services/user_service.dart';
import 'package:arcade_aura/widgets/gradient_scaffold.dart';
import 'package:arcade_aura/widgets/neon_button.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  Future<void> _signup() async {
    try {
      setState(() => _loading = true);
      final cred = await AuthService.instance.signUp(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
      await UserService.instance.createIfMissing(
        uid: cred.user!.uid,
        username: _username.text.trim(),
        email: _email.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
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
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _username, decoration: const InputDecoration(labelText: 'Username')),
            const SizedBox(height: 8),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
            const SizedBox(height: 16),
            if (_loading) const CircularProgressIndicator() else NeonButton(label: 'Create Account', onTap: _signup),
          ],
        ),
      ),
    );
  }
}
