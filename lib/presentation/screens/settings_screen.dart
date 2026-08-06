import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/crossfade_config.dart';
import '../providers/settings_providers.dart';
import 'equalizer_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(playbackSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        data: (settings) {
          final controller = ref.read(settingsControllerProvider);

          return ListView(
            children: [
              const _SectionHeader(title: 'Audio Engine'),
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('Equalizer'),
                subtitle: const Text('10-band EQ and presets'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EqualizerScreen()),
                  );
                },
              ),
              ListTile(
                title: const Text('Crossfade Mode'),
                subtitle: Text(settings.crossfade.mode.name.toUpperCase()),
                trailing: DropdownButton<CrossfadeMode>(
                  value: settings.crossfade.mode,
                  underline: const SizedBox(),
                  items: CrossfadeMode.values.map((mode) {
                    return DropdownMenuItem(value: mode, child: Text(mode.name));
                  }).toList(),
                  onChanged: (mode) {
                    if (mode != null) {
                      controller.updateCrossfade(mode, settings.crossfade.duration);
                    }
                  },
                ),
              ),
              if (settings.crossfade.mode != CrossfadeMode.disabled)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Crossfade Duration: ${settings.crossfade.duration.inSeconds}s'),
                      Slider(
                        value: settings.crossfade.duration.inSeconds.toDouble(),
                        min: 0, // <--- FIX: Ahora permite 0 segundos
                        max: 12,
                        divisions: 12, // <--- FIX: 12 divisiones para 0 a 12
                        label: '${settings.crossfade.duration.inSeconds}s',
                        onChanged: (val) {
                          controller.updateCrossfade(
                            settings.crossfade.mode,
                            Duration(seconds: val.toInt()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              const Divider(),
              
              const _SectionHeader(title: 'Playback Speed'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Speed: ${settings.speed.multiplier.toStringAsFixed(2)}x'),
                    Slider(
                      value: settings.speed.multiplier,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      label: '${settings.speed.multiplier.toStringAsFixed(2)}x',
                      onChanged: (val) {
                        controller.updateSpeed(val, settings.speed.pitchCorrectionEnabled);
                      },
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                title: const Text('Pitch Correction'),
                subtitle: const Text('Keep original pitch when changing speed'),
                value: settings.speed.pitchCorrectionEnabled,
                onChanged: (val) {
                  controller.updateSpeed(settings.speed.multiplier, val);
                },
              ),
              const Divider(),

              const _SectionHeader(title: 'Library'),
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Force Library Rescan'),
                subtitle: const Text('Check indexed folders for new or deleted files'),
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Scanning library...')),
                  );
                  final error = await controller.forceLibraryRefresh();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error ?? 'Library scan complete.')),
                    );
                  }
                },
              ),
              const Divider(),

              const _SectionHeader(title: 'Appearance (Preview)'),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Theme'),
                subtitle: const Text('System Default'),
                onTap: () {
                  // Scaffolded for 3.10
                },
              ),
              ListTile(
                leading: const Icon(Icons.lens_blur),
                title: const Text('Adaptive Warmth'),
                subtitle: const Text('Vivo (High Performance)'),
                onTap: () {
                  // Scaffolded for 3.10
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}