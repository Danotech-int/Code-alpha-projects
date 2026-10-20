import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF385747),
          brightness: brightness,
        ).copyWith(
          primary: isDark ? const Color(0xFFB5CFB7) : const Color(0xFF345543),
          onPrimary: isDark ? const Color(0xFF193326) : Colors.white,
          surface: isDark ? const Color(0xFF171F1C) : const Color(0xFFFAF9F5),
          onSurface: isDark ? const Color(0xFFE9ECE3) : const Color(0xFF263C31),
          onSurfaceVariant: isDark
              ? const Color(0xFFBBC6BC)
              : const Color(0xFF5D6C61),
          surfaceContainerLow: isDark
              ? const Color(0xFF212E27)
              : const Color(0xFFEBEFE5),
          outlineVariant: isDark
              ? const Color(0xFF3E4E43)
              : const Color(0xFFD5DDCE),
          tertiary: isDark ? const Color(0xFFE7B892) : const Color(0xFF8C5535),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 58),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
