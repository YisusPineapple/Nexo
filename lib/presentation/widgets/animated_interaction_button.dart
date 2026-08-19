import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedInteractionButton extends StatefulWidget {
  const AnimatedInteractionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.isActive,
    this.showBurst = true,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isActive;
  final bool showBurst;

  @override
  State<AnimatedInteractionButton> createState() => _AnimatedInteractionButtonState();
}

class _AnimatedInteractionButtonState extends State<AnimatedInteractionButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _burstController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.6).chain(CurveTween(curve: Curves.easeOut)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.3).chain(CurveTween(curve: Curves.elasticOut)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 30),
    ]).animate(_scaleController);

    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedInteractionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive && widget.isActive) {
      _scaleController.forward(from: 0.0);
      if (widget.showBurst) {
        _burstController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _burstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Strict SizedBox prevents layout shifts when the burst is added/removed
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.isActive && widget.showBurst)
            AnimatedBuilder(
              animation: _burstController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(48, 48),
                  painter: _BurstPainter(
                    progress: _burstController.value,
                    color: widget.color,
                  ),
                );
              },
            ),
          ScaleTransition(
            scale: _scaleAnimation,
            child: IconButton(
              icon: Icon(widget.icon),
              color: widget.color,
              onPressed: () {
                widget.onPressed();
                if (!widget.isActive) {
                  _scaleController.forward(from: 0.0);
                  if (widget.showBurst) {
                    _burstController.forward(from: 0.0);
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0.0 || progress == 1.0) return;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: (1.0 - progress).clamp(0.0, 1.0));

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 1.5;
    final currentRadius = maxRadius * Curves.easeOutCubic.transform(progress);

    const particleCount = 6;
    const angleStep = (2 * math.pi) / particleCount;

    for (int i = 0; i < particleCount; i++) {
      final angle = i * angleStep - (math.pi / 2);
      final dx = center.dx + currentRadius * math.cos(angle);
      final dy = center.dy + currentRadius * math.sin(angle);
      
      final particleSize = 3.0 * (1.0 - progress);
      
      canvas.drawCircle(Offset(dx, dy), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}