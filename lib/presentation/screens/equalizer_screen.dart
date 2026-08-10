import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_providers.dart';

class EqualizerScreen extends ConsumerWidget {
  const EqualizerScreen({super.key});

  static const _frequencies = [
    '31',
    '62',
    '125',
    '250',
    '500',
    '1k',
    '2k',
    '4k',
    '8k',
    '16k'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = ref.watch(equalizerEnabledProvider);
    final bands = ref.watch(equalizerBandsProvider);
    final preset = ref.watch(equalizerPresetProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equalizer'),
        actions: [
          Switch(
            value: isEnabled,
            onChanged: (val) =>
                ref.read(equalizerEnabledProvider.notifier).state = val,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Preset:'),
                DropdownButton<String>(
                  value: preset,
                  items: const [
                    DropdownMenuItem(value: 'Custom', child: Text('Custom')),
                    DropdownMenuItem(value: 'Flat', child: Text('Flat')),
                    DropdownMenuItem(
                        value: 'Bass Boost', child: Text('Bass Boost')),
                    DropdownMenuItem(
                        value: 'Acoustic', child: Text('Acoustic')),
                  ],
                  onChanged: isEnabled
                      ? (val) {
                          if (val != null) {
                            ref.read(equalizerPresetProvider.notifier).state =
                                val;
                            if (val == 'Flat') {
                              ref.read(equalizerBandsProvider.notifier).state =
                                  List.filled(10, 0.0);
                            } else if (val == 'Bass Boost') {
                              ref.read(equalizerBandsProvider.notifier).state =
                                  [
                                6.0,
                                5.0,
                                4.0,
                                2.0,
                                0.0,
                                0.0,
                                0.0,
                                0.0,
                                0.0,
                                0.0
                              ];
                            } else if (val == 'Acoustic') {
                              ref.read(equalizerBandsProvider.notifier).state =
                                  [
                                3.0,
                                4.0,
                                3.0,
                                1.0,
                                1.0,
                                1.0,
                                2.0,
                                3.0,
                                2.0,
                                1.0
                              ];
                            }
                          }
                        }
                      : null,
                ),
              ],
            ),
          ),

          // Visual EQ Curve
          Container(
            height: 120,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: CustomPaint(
              painter: _EqCurvePainter(
                bands: bands,
                color: isEnabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),

          Expanded(
            child: Opacity(
              opacity: isEnabled ? 1.0 : 0.5,
              child: IgnorePointer(
                ignoring: !isEnabled,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(10, (index) {
                    return _EqBand(
                      frequency: _frequencies[index],
                      value: bands[index],
                      onChanged: (val) {
                        final newBands = List<double>.from(bands);
                        newBands[index] = val;
                        ref.read(equalizerBandsProvider.notifier).state =
                            newBands;
                        ref.read(equalizerPresetProvider.notifier).state =
                            'Custom';
                      },
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _EqCurvePainter extends CustomPainter {
  _EqCurvePainter({required this.bands, required this.color});
  final List<double> bands;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (bands.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.4),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (bands.length - 1);

    // Map -15..15 to height..0
    double getY(double value) {
      final normalized = (value + 15) / 30; // 0.0 to 1.0
      return size.height - (normalized * size.height);
    }

    final points = <Offset>[];
    for (var i = 0; i < bands.length; i++) {
      points.add(Offset(i * stepX, getY(bands[i])));
    }

    path.moveTo(points.first.dx, points.first.dy);
    fillPath.moveTo(points.first.dx, size.height);
    fillPath.lineTo(points.first.dx, points.first.dy);

    // Draw smooth cubic bezier curve
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];

      final controlPointX = p0.dx + (p1.dx - p0.dx) / 2;

      path.cubicTo(
        controlPointX,
        p0.dy,
        controlPointX,
        p1.dy,
        p1.dx,
        p1.dy,
      );

      fillPath.cubicTo(
        controlPointX,
        p0.dy,
        controlPointX,
        p1.dy,
        p1.dx,
        p1.dy,
      );
    }

    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _EqCurvePainter oldDelegate) {
    for (var i = 0; i < bands.length; i++) {
      if (bands[i] != oldDelegate.bands[i]) return true;
    }
    return color != oldDelegate.color;
  }
}

class _EqBand extends StatelessWidget {
  const _EqBand({
    required this.frequency,
    required this.value,
    required this.onChanged,
  });

  final String frequency;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${value > 0 ? '+' : ''}${value.toStringAsFixed(1)}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: value,
              min: -15.0,
              max: 15.0,
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          frequency,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
