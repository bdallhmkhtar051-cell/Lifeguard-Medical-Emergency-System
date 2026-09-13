import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const navy = Color(0xFF0F172A);
  static const slate = Color(0xFF1E293B);
  static const canvas = Color(0xFFF4F8FC);
  static const border = Color(0xFFDFE8F3);
  static const blue = Color(0xFF2563EB);
  static const teal = Color(0xFF0F766E);

  static ThemeData light() {
    // The React reference uses a clinical navy canvas with blue actions and
    // restrained emergency red. Keeping these tokens here gives later patient
    // and provider screens one consistent visual language.
    const seed = blue;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ).copyWith(
          primary: blue,
          secondary: teal,
          surface: Colors.white,
          onSurface: navy,
          surfaceTint: Colors.transparent,
          outlineVariant: border,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      visualDensity: VisualDensity.standard,
      textTheme: ThemeData.light().textTheme
          .apply(bodyColor: navy, displayColor: navy)
          .copyWith(
            titleLarge: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: navy,
              letterSpacing: -.5,
            ),
            titleMedium: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: navy,
            ),
            bodyMedium: const TextStyle(fontSize: 14, height: 1.5, color: navy),
            bodyLarge: const TextStyle(fontSize: 16, height: 1.5, color: navy),
          ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: navy,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          backgroundColor: blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: blue, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: navy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Stronger boundaries and focus indicators for the authenticated
  /// workspace. This remains a light theme to preserve clinical color meaning.
  static ThemeData highContrast() {
    final base = light();
    return base.copyWith(
      scaffoldBackgroundColor: Colors.white,
      colorScheme: base.colorScheme.copyWith(
        primary: const Color(0xFF0039A6),
        secondary: const Color(0xFF006B5B),
        outline: Colors.black,
        outlineVariant: const Color(0xFF475569),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Colors.black, thickness: 2),
    );
  }
}
