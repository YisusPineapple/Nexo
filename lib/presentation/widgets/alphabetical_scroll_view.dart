import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AlphabeticalScrollView extends StatefulWidget {
  const AlphabeticalScrollView({
    super.key,
    required this.child,
    required this.controller,
    required this.itemExtent,
    this.sectionIndex,
    this.itemCount,
    this.labelBuilder,
    this.crossAxisCount = 1,
    this.version,
    this.railWidth = 32,
    this.topPadding = 8,
    this.bottomPadding = 8,
  }) : assert(sectionIndex != null ||
            (itemCount != null && labelBuilder != null));

  final Widget child;
  final ScrollController controller;
  final double itemExtent;

  /// A precomputed list of (Letter, FirstIndex) from SQLite.
  /// Used for virtualized lists (like Songs) to save RAM.
  final List<(String letter, int firstIndex)>? sectionIndex;

  /// Used for in-memory lists (like Albums, Artists) to compute the index on the fly.
  final int? itemCount;
  final String Function(int index)? labelBuilder;

  final int crossAxisCount;
  final Object? version;
  final double railWidth;
  final double topPadding;
  final double bottomPadding;

  @override
  State<AlphabeticalScrollView> createState() => _AlphabeticalScrollViewState();
}

class _AlphabeticalScrollViewState extends State<AlphabeticalScrollView> {
  List<(String, int)> _sections = const [];
  final ValueNotifier<String?> _activeSection = ValueNotifier(null);
  int? _lastPointerBucket;

  @override
  void initState() {
    super.initState();
    _sections = widget.sectionIndex ?? _computeIndex();
  }

  @override
  void didUpdateWidget(covariant AlphabeticalScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sectionIndex != null) {
      if (oldWidget.sectionIndex != widget.sectionIndex) {
        setState(() => _sections = widget.sectionIndex!);
      }
    } else if (oldWidget.itemCount != widget.itemCount ||
        oldWidget.version != widget.version) {
      setState(() => _sections = _computeIndex());
    }
  }

  @override
  void dispose() {
    _activeSection.dispose();
    super.dispose();
  }

  String _cleanSectionKey(String raw) {
    if (raw.isEmpty) return '#';
    final firstChar = raw.trim().characters.first.toUpperCase();

    if (RegExp(r'[0-9]').hasMatch(firstChar)) return '#';

    const withDia = 'ÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÑ';
    const withoutDia = 'AAAAAAEEEEIIIIOOOOOUUUUN';
    final diaIndex = withDia.indexOf(firstChar);
    if (diaIndex != -1) return withoutDia[diaIndex];

    if (RegExp(r'[A-ZА-Я]').hasMatch(firstChar)) return firstChar;

    return '#';
  }

  List<(String, int)> _computeIndex() {
    if (widget.itemCount == null || widget.labelBuilder == null) return [];
    final firstIndex = <String, int>{};
    for (var i = 0; i < widget.itemCount!; i++) {
      final raw = widget.labelBuilder!(i);
      final key = _cleanSectionKey(raw);
      firstIndex.putIfAbsent(key, () => i);
    }
    return firstIndex.entries.map((e) => (e.key, e.value)).toList();
  }

  void _handlePointer(Offset localPosition, double railHeight) {
    if (_sections.isEmpty || railHeight <= 0) return;

    final ratio = (localPosition.dy / railHeight).clamp(0.0, 0.999);
    final bucket = (ratio * _sections.length).floor();

    if (bucket == _lastPointerBucket) return;
    _lastPointerBucket = bucket;

    final section = _sections[bucket];
    _activeSection.value = section.$1;
    HapticFeedback.selectionClick();

    final targetIndex = section.$2;
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
        Row(
          children: [
            Expanded(
              child: RepaintBoundary(child: widget.child),
            ),
            if (_sections.length > 1)
              Padding(
                padding: EdgeInsets.only(
                  top: widget.topPadding,
                  bottom: widget.bottomPadding,
                  right: 2,
                ),
                child: SizedBox(
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
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface
                                .withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ValueListenableBuilder<String?>(
                            valueListenable: _activeSection,
                            builder: (context, active, _) {
                              return Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  for (final section in _sections)
                                    Text(
                                      section.$1,
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        fontSize:
                                            _sections.length > 25 ? 8 : 10,
                                        fontWeight: section.$1 == active
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: section.$1 == active
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurfaceVariant
                                                .withValues(alpha: 0.8),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
        IgnorePointer(
          child: Center(
            child: ValueListenableBuilder<String?>(
              valueListenable: _activeSection,
              builder: (context, active, _) {
                return AnimatedScale(
                  duration: const Duration(milliseconds: 150),
                  scale: active == null ? 0.6 : 1.0,
                  curve: Curves.easeOutBack,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 100),
                    opacity: active == null ? 0.0 : 1.0,
                    child: Container(
                      width: 90,
                      height: 90,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Text(
                        active ?? '',
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
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
