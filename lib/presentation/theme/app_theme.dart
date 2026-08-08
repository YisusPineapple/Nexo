import 'package:flutter/material.dart';

/// Defines the "Warm" visual identity of Nexo.
/// Replaces the generic Material defaults with a terracotta/cream palette
/// that feels human, cozy, and less clinical.
class AppTheme {
  const AppTheme._();

  // Core brand colors
  static const Color _seedColor = Color(0xFFD95D39); // Warm Terracotta
  static const Color _surfaceLight = Color(0xFFFDFBF7); // Creamy off-white
  static const Color _surfaceDark = Color(0xFF1A1614); // Deep warm gray/brown

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
        surface: _surfaceLight,
        surfaceContainerHighest: const Color(0xFFF0EBE1),
      ),
      fontFamily: 'Outfit', // Will use the OS default, but styled warmly
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        elevation: 0,
        indicatorShape: StadiumBorder(),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        useIndicator: true,
        indicatorShape: StadiumBorder(),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
        surface: _surfaceDark,
        surfaceContainerHighest: const Color(0xFF2A2421),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        elevation: 0,
        indicatorShape: StadiumBorder(),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        useIndicator: true,
        indicatorShape: StadiumBorder(),
      ),
    );
  }
}