import 'package:flutter/material.dart';

class BloomTheme {
  /// Soft green brand seed — Bloom identity.
  static const Color seed = Color(0xFF3D8B6E);
  static const Color accentGreen = Color(0xFF2E7D4F);
  static const Color sport = Color(0xFF2E7D4F);
  static const Color wellbeing = Color(0xFFD4849A);
  static const Color tasks = Color(0xFF5B8DEF);
  static const Color puzzle = Color(0xFF9B7EDE);
  /// Neutral Bloom accent for Planning chrome (event colors stay typed).
  static const Color planning = Color(0xFF5A8F7B);
  static const Color scaffoldLight = Color(0xFFF3F9F5);
  static const Color scaffoldDark = Color(0xFF101814);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: accentGreen,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: scaffoldLight,
      colorScheme: scheme,
      fontFamily: 'Arial',
      cardTheme: CardThemeData(
        elevation: 1.5,
        shadowColor: accentGreen.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontWeight: FontWeight.w600, fontSize: 12);
          }
          return const TextStyle(fontSize: 12);
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldDark,
      colorScheme: scheme,
      fontFamily: 'Arial',
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontWeight: FontWeight.w600, fontSize: 12);
          }
          return const TextStyle(fontSize: 12);
        }),
      ),
    );
  }
}
