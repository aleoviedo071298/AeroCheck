import 'package:flutter/material.dart';

ThemeData buildAeroCheckTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF0F766E),
        brightness: brightness,
      ).copyWith(
        primary: const Color(0xFF0F766E),
        secondary: const Color(0xFFF59E0B),
        tertiary: const Color(0xFF2563EB),
        surface: isDark ? const Color(0xFF101820) : const Color(0xFFF6F8F9),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF081014)
        : const Color(0xFFF3F6F8),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF101820) : Colors.white,
      foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: isDark ? const Color(0xFF101820) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isDark ? const Color(0xFF25323B) : const Color(0xFFE1E7EA),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      indicatorColor: scheme.primary.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
