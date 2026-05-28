import 'package:flutter/material.dart';

class AppTheme {
  static const _bgStart = Color(0xFF120528);
  static const _bgEnd = Color(0xFF1E1E3F);
  static const neonBlue = Color(0xFF00E5FF);
  static const neonPink = Color(0xFFFF4DFF);

  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme.dark(
        primary: neonBlue,
        secondary: neonPink,
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  static BoxDecoration pageGradient() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_bgStart, _bgEnd],
      ),
    );
  }
}
