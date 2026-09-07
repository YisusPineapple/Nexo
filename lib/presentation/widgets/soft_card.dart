import 'package:flutter/material.dart';

import '../theme/nexo_tokens.dart';

/// A universal card widget that applies Nexo's "Warm & Soft" design tokens.
///
/// Solves the common Flutter issue where a Container's background color
/// hides the InkWell ripple effect, by using a transparent Material widget
/// over the decorated container.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.color,
    this.borderRadius = NexoTokens.radiusMedium,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.isActive = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final double borderRadius;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  /// If true, applies a slightly more pronounced shadow and border.
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.surface;

    return AnimatedContainer(
      duration: NexoTokens.animDurationNormal,
      curve: NexoTokens.defaultCurve,
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isActive
            ? NexoTokens.activeShadow(context)
            : NexoTokens.softShadow(context),
        border: isActive
            ? Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 1.5,
              )
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
