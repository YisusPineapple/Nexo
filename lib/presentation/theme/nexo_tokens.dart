import 'package:flutter/material.dart';

/// Centralized design tokens for Nexo's "Warm & Soft" / M3 Expressive identity.
/// Ensures consistency across the app without hardcoding values in widgets.
class NexoTokens {
  const NexoTokens._();

  // --- Border Radii ---
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusExtraLarge = 32.0;

  // --- Animations ---
  static const Duration animDurationQuick = Duration(milliseconds: 150);
  static const Duration animDurationNormal = Duration(milliseconds: 300);
  static const Curve defaultCurve = Curves.easeOutCubic;

  // --- Shadows ---
  /// A subtle, wide shadow that gives elements a "floating" feel without
  /// being harsh. Adapts to the current theme brightness.
  static List<BoxShadow> softShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.2)
            : Colors.black.withValues(alpha: 0.04),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];
  }

  /// A slightly more pronounced shadow for active/hovered states.
  static List<BoxShadow> activeShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.3)
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
  }
}
