import 'package:arcade_aura/firebase_options.dart';
import 'package:arcade_aura/screens/auth/login_screen.dart';
import 'package:arcade_aura/screens/home/home_screen.dart';
import 'package:arcade_aura/services/auth_service.dart';
import 'package:arcade_aura/utils/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ArcadeAuraApp());
}

class ArcadeAuraApp extends StatelessWidget {
  const ArcadeAuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Arcade Aura',
      theme: AppTheme.darkTheme(),
      home: StreamBuilder<User?>(
        stream: AuthService.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoginScreen();
          return const HomeScreen();
        },
      ),
    );
  }
}
