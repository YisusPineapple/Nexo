import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AlphabeticalScrollView extends StatefulWidget {
  const AlphabeticalScrollView({
    super.key,
    required this.child,
    required this.controller,
    required this.itemCount,
    required this.itemExtent,
    required this.labelBuilder,
    this.crossAxisCount = 1, // FIX: Added support for GridViews
    this.version,
    this.railWidth = 40,
    this.topPadding = 0,
    this.bottomPadding = 0,
  });

  final Widget child;
  final ScrollController controller;
  final int itemCount;
  final double itemExtent;
  final String Function(int index) labelBuilder;
  final int crossAxisCount;
  final Object? version;
  final double railWidth;
  final double topPadding;
  final double bottomPadding;

  @override
  State<AlphabeticalScrollView> createState() => _AlphabeticalScrollViewState();
}

class _AlphabeticalScrollViewState extends State<AlphabeticalScrollView> {
  List<String> _sections = const [];
  Map<String, int> _firstIndexForSection = const {};

  final ValueNotifier<String?> _activeSection = ValueNotifier(null);
  int? _lastPointerBucket;

  @override
  void initState() {
    super.initState();
    final index = _computeIndex();
    _sections = index.$1;
    _firstIndexForSection = index.$2;
  }

  @override
  void didUpdateWidget(covariant AlphabeticalScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount ||
        oldWidget.version != widget.version) {
      final index = _computeIndex();
      setState(() {
        _sections = index.$1;
        _firstIndexForSection = index.$2;
      });
    }
  }

  @override
  void dispose() {
    _activeSection.dispose();
    super.dispose();
  }

  String _removeDiacritics(String str) {
    const withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    const withoutDia = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }
    return str;
  }

  (List<String>, Map<String, int>) _computeIndex() {
    final firstIndex = <String, int>{};
    for (var i = 0; i < widget.itemCount; i++) {
      final raw = widget.labelBuilder(i);
      if (raw.isEmpty) continue;
      
      // FIX: We no longer force A-Z. We accept numbers, dates, etc.
      final key = _removeDiacritics(raw);
      firstIndex.putIfAbsent(key, () => i);
    }
    // FIX: Do NOT sort the keys alphabetically. Keep the natural order 
    // of the list (which is already sorted by the provider).
    final sections = firstIndex.keys.toList();
    return (sections, firstIndex);
  }

  void _handlePointer(Offset localPosition, double railHeight) {
    if (_sections.isEmpty || railHeight <= 0) return;
    final ratio = (localPosition.dy / railHeight).clamp(0.0, 0.999);
    final bucket = (ratio * _sections.length).floor();
    if (bucket == _lastPointerBucket) return; 
    _lastPointerBucket = bucket;

    final section = _sections[bucket];
    _activeSection.value = section;
    HapticFeedback.selectionClick();

    final targetIndex = _firstIndexForSection[section]!;
    // FIX: Calculate row index to support GridViews
    final rowIndex = targetIndex ~/ widget.crossAxisCount;
    
    final maxExtent = widget.controller.hasClients
        ? widget.controller.position.maxScrollExtent
        : double.infinity;
    final offset = (rowIndex * widget.itemExtent).clamp(0.0, maxExtent);
    widget.controller.jumpTo(offset);
  }

  void _endDrag() {
    _lastPointerBucket = null;
    _activeSection.value = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        RepaintBoundary(child: widget.child),
        if (_sections.isNotEmpty)
          Positioned(
            right: 0,
            top: widget.topPadding,
            bottom: widget.bottomPadding,
            width: widget.railWidth,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final railHeight = constraints.maxHeight;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragStart: (d) =>
                      _handlePointer(d.localPosition, railHeight),
                  onVerticalDragUpdate: (d) =>
                      _handlePointer(d.localPosition, railHeight),
                  onVerticalDragEnd: (_) => _endDrag(),
                  onVerticalDragCancel: _endDrag,
                  onTapDown: (d) =>
                      _handlePointer(d.localPosition, railHeight),
                  onTapUp: (_) => _endDrag(),
                  child: ValueListenableBuilder<String?>(
                    valueListenable: _activeSection,
                    builder: (context, active, _) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final section in _sections)
                            Text(
                              section,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                fontWeight: section == active
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: section == active
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        IgnorePointer(
          child: Center(
            child: ValueListenableBuilder<String?>(
              valueListenable: _activeSection,
              builder: (context, active, _) {
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 100),
                  opacity: active == null ? 0 : 1,
                  child: Container(
                    width: 80,
                    height: 80,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      active ?? '',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
