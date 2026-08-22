import 'dart:async';
import 'package:flutter/material.dart';

class MarqueeText extends StatefulWidget {
  const MarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.pauseDuration = const Duration(seconds: 3),
    this.scrollVelocity = 30.0, // pixels per second
  });

  final String text;
  final TextStyle? style;
  final Duration pauseDuration;
  final double scrollVelocity;

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  final ScrollController _scrollController = ScrollController();
  bool _needsScroll = false;
  Timer? _timer;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndStart());
  }

  @override
  void didUpdateWidget(covariant MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      _stopAnimation();
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndStart());
    }
  }

  @override
  void dispose() {
    _stopAnimation();
    _scrollController.dispose();
    super.dispose();
  }

  void _stopAnimation() {
    _timer?.cancel();
    _isAnimating = false;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _checkAndStart() {
    if (!mounted || !_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    setState(() {
      _needsScroll = maxScroll > 0;
    });

    if (_needsScroll && !_isAnimating) {
      _startAnimation(maxScroll);
    }
  }

  void _startAnimation(double maxScroll) {
    _isAnimating = true;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!mounted || !_scrollController.hasClients) {
        timer.cancel();
        return;
      }

      timer.cancel();
      
      await Future.delayed(widget.pauseDuration);
      if (!mounted || !_scrollController.hasClients) return;

      final duration = Duration(
        milliseconds: (maxScroll / widget.scrollVelocity * 1000).toInt(),
      );

      await _scrollController.animateTo(
        maxScroll,
        duration: duration,
        curve: Curves.linear,
      );

      if (!mounted || !_scrollController.hasClients) return;
      
      await Future.delayed(widget.pauseDuration);
      if (!mounted || !_scrollController.hasClients) return;
      
      await _scrollController.animateTo(
        0,
        duration: duration,
        curve: Curves.linear,
      );
      
      if (mounted && _needsScroll) {
        _startAnimation(maxScroll);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget scrollView = SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
        softWrap: false,
      ),
    );

    if (_needsScroll) {
      return ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            // FIX: Reduced the fade area so text is more readable at the edges
            stops: [0.0, 0.02, 0.98, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: scrollView,
      );
    }

    return scrollView;
  }
}