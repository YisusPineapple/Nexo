import 'package:flutter/material.dart';

/// Defines the "Warm" visual identity of Nexo.
/// Replaces the generic Material defaults with a terracotta/cream palette
/// that feels human, cozy, and less clinical.
class AppTheme {
  const AppTheme._();

  // Core brand colors
  static const Color _seedColor = Color(0xFFD95D39); // Warm Terracotta
  static const Color _surfaceLight = Color(0xFFFDFBF7); // Creamy off-white
  static const Color _surfaceDark = Color(0xFF201511); // Espresso dark

  // Smooth page transitions for a premium feel without heavy GPU cost
  static const _pageTransitions = PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
    },
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
        surface: _surfaceLight,
        surfaceContainerHighest: const Color(0xFFF0EBE1),
      ),
      fontFamily: 'Outfit',
      pageTransitionsTheme: _pageTransitions,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
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
        surfaceContainerHighest: const Color(0xFF2A1F1A),
      ),
      fontFamily: 'Outfit',
      pageTransitionsTheme: _pageTransitions,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
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