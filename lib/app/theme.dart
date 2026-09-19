import 'package:flutter/material.dart';

class BloomTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFFBFD),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFE8A7C4),
        brightness: Brightness.light,
      ),
      fontFamily: 'Arial',
    );
  }
}