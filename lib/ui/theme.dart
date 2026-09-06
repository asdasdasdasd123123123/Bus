import 'package:flutter/material.dart';

ThemeData buildAppTheme({required Brightness brightness}) {
  final base = ColorScheme.fromSeed(
    seedColor: const Color(0xFFC62828),
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: base,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: AppBarTheme(
      backgroundColor: base.surface,
      foregroundColor: base.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
  );
}
