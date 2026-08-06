import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_providers.dart';

class EqualizerScreen extends ConsumerWidget {
  const EqualizerScreen({super.key});

  static const _frequencies = [
    '31', '62', '125', '250', '500', '1k', '2k', '4k', '8k', '16k'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = ref.watch(equalizerEnabledProvider);
    final bands = ref.watch(equalizerBandsProvider);
    final preset = ref.watch(equalizerPresetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equalizer'),
        actions: [
          Switch(
            value: isEnabled,
            onChanged: (val) => ref.read(equalizerEnabledProvider.notifier).state = val,
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
                    DropdownMenuItem(value: 'Bass Boost', child: Text('Bass Boost')),
                    DropdownMenuItem(value: 'Acoustic', child: Text('Acoustic')),
                  ],
                  onChanged: isEnabled ? (val) {
                    if (val != null) {
                      ref.read(equalizerPresetProvider.notifier).state = val;
                      if (val == 'Flat') {
                        ref.read(equalizerBandsProvider.notifier).state = List.filled(10, 0.0);
                      } else if (val == 'Bass Boost') {
                        ref.read(equalizerBandsProvider.notifier).state = [6.0, 5.0, 4.0, 2.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
                      } else if (val == 'Acoustic') {
                        ref.read(equalizerBandsProvider.notifier).state = [3.0, 4.0, 3.0, 1.0, 1.0, 1.0, 2.0, 3.0, 2.0, 1.0];
                      }
                    }
                  } : null,
                ),
              ],
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
                        ref.read(equalizerBandsProvider.notifier).state = newBands;
                        // Si el usuario mueve un slider manualmente, cambiamos el preset a Custom
                        ref.read(equalizerPresetProvider.notifier).state = 'Custom';
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
          style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}