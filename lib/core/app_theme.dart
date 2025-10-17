import 'package:flutter/material.dart';

ThemeData buildTheme(Brightness brightness) {
  final base = ThemeData(
    colorSchemeSeed: const Color(0xFF4F46E5),
    useMaterial3: true,
    brightness: brightness,
  );
  return base.copyWith(
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    visualDensity: VisualDensity.comfortable,
  );
}
