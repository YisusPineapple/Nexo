import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_preferences.dart';
import '../providers/app_preferences_provider.dart';
import '../theme/nexo_tokens.dart';

/// A universal card widget that applies Nexo's "Warm & Soft" design tokens.
/// Includes an M3-style bounce effect on press, scaled by PerformanceProfile.
class SoftCard extends ConsumerStatefulWidget {
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
  final bool isActive;

  @override
  ConsumerState<SoftCard> createState() => _SoftCardState();
}

class _SoftCardState extends ConsumerState<SoftCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = const AlwaysStoppedAnimation(1.0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateScaleAnimation();
  }

  void _updateScaleAnimation() {
    final profile = ref.read(appPreferencesProvider).performanceProfile;
    final double lowerBound = switch (profile) {
      PerformanceProfile.vivo => 0.92,
      PerformanceProfile.balanced => 0.96,
      PerformanceProfile.eco => 1.0,
      PerformanceProfile.custom => 0.96,
    };

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: lowerBound,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      _updateScaleAnimation();
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null || widget.onLongPress != null) {
      _controller.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null || widget.onLongPress != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = widget.color ?? theme.colorScheme.surface;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: NexoTokens.animDurationNormal,
        curve: NexoTokens.defaultCurve,
        margin: widget.margin,
        decoration: BoxDecoration(
          color: effectiveColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: widget.isActive
              ? NexoTokens.activeShadow(context)
              : NexoTokens.softShadow(context),
          border: widget.isActive
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
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            child: Padding(
              padding: widget.padding,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
