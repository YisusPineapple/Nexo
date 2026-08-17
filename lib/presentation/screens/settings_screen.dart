import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../domain/entities/app_preferences.dart';
import '../../domain/entities/crossfade_config.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/backup_providers.dart';
import '../providers/settings_providers.dart';
import 'equalizer_screen.dart';
import 'library/folder_management_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _showBackupDialog(BuildContext context, WidgetRef ref) async {
    final destinationDirectory = await FilePicker.platform.getDirectoryPath();
    if (destinationDirectory == null || !context.mounted) {
      return;
    }

    bool includeLibrary = true;
    bool includePlaylists = true;
    bool includeSettings = true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Destination: $destinationDirectory',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              const Text('Select what to include in the backup.'),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Library'),
                value: includeLibrary,
                onChanged: (value) =>
                    setState(() => includeLibrary = value ?? true),
              ),
              CheckboxListTile(
                title: const Text('Playlists'),
                value: includePlaylists,
                onChanged: (value) =>
                    setState(() => includePlaylists = value ?? true),
              ),
              CheckboxListTile(
                title: const Text('Settings & preferences'),
                value: includeSettings,
                onChanged: (value) =>
                    setState(() => includeSettings = value ?? true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                if (!context.mounted) return;

                unawaited(
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Creating backup...'),
                        ],
                      ),
                    ),
                  ),
                );

                final backupPath =
                    await ref.read(backupControllerProvider).createBackup(
                          includeLibrary: includeLibrary,
                          includePlaylists: includePlaylists,
                          includeSettings: includeSettings,
                          destinationDirectory: destinationDirectory,
                        );

                if (!context.mounted) return;
                Navigator.pop(context);

                if (backupPath == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Backup creation failed.'),
                    ),
                  );
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Backup saved to: $backupPath'),
                  ),
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImportBackup(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    final path = result?.files.single.path;
    if (path == null || !context.mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup?'),
        content: const Text(
          'This will overwrite your current library, playlists, and settings. The app will close after restoration.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore & Exit'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Restoring backup...'),
            ],
          ),
        ),
      ),
    );

    final error = await ref.read(backupControllerProvider).restoreBackup(path);

    if (!context.mounted) return;
    Navigator.pop(context);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      await SystemNavigator.pop();
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(playbackSettingsProvider);
    final prefs = ref.watch(appPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        data: (settings) {
          final controller = ref.read(settingsControllerProvider);
          return ListView(
            children: [
              const _SectionHeader(title: 'Audio Engine'),
              ListTile(
                leading: const Icon(PhosphorIconsRegular.slidersHorizontal),
                title: const Text('Equalizer'),
                subtitle: const Text('10-band EQ and presets'),
                trailing: const Icon(PhosphorIconsRegular.caretRight),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const EqualizerScreen()));
                },
              ),
              ListTile(
                title: const Text('Crossfade Mode'),
                subtitle: Text(settings.crossfade.mode.name.toUpperCase()),
                trailing: DropdownButton<CrossfadeMode>(
                  value: settings.crossfade.mode,
                  underline: const SizedBox(),
                  items: CrossfadeMode.values
                      .map((mode) =>
                          DropdownMenuItem(value: mode, child: Text(mode.name)))
                      .toList(),
                  onChanged: (mode) {
                    if (mode != null) {
                      controller.updateCrossfade(
                          mode, settings.crossfade.duration,
                          isAutoDuration: settings.crossfade.isAutoDuration);
                    }
                  },
                ),
              ),
              if (settings.crossfade.mode != CrossfadeMode.disabled) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (settings.crossfade.mode ==
                              CrossfadeMode.intelligent ||
                          settings.crossfade.mode == CrossfadeMode.autoMix) ...[
                        Row(
                          children: [
                            const Text('Duration control: '),
                            const Spacer(),
                            ChoiceChip(
                              label: const Text('Manual'),
                              selected: !settings.crossfade.isAutoDuration,
                              onSelected: (_) => controller.updateCrossfade(
                                  settings.crossfade.mode,
                                  settings.crossfade.duration,
                                  isAutoDuration: false),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Auto'),
                              selected: settings.crossfade.isAutoDuration,
                              onSelected: (_) => controller.updateCrossfade(
                                  settings.crossfade.mode,
                                  settings.crossfade.duration,
                                  isAutoDuration: true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (!settings.crossfade.isAutoDuration) ...[
                        Text(
                            'Crossfade Duration: ${settings.crossfade.duration.inSeconds}s'),
                        Slider(
                          value:
                              settings.crossfade.duration.inSeconds.toDouble(),
                          min: 0,
                          max: 12,
                          divisions: 12,
                          label: '${settings.crossfade.duration.inSeconds}s',
                          onChanged: (val) => controller.updateCrossfade(
                              settings.crossfade.mode,
                              Duration(seconds: val.toInt()),
                              isAutoDuration:
                                  settings.crossfade.isAutoDuration),
                        ),
                      ] else ...[
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0, bottom: 16.0),
                          child: Text(
                              'The system will automatically choose the optimal duration.',
                              style: TextStyle(
                                  fontSize: 12, fontStyle: FontStyle.italic)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const Divider(),
              const _SectionHeader(title: 'Playback Speed'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Speed: ${settings.speed.multiplier.toStringAsFixed(2)}x'),
                    Slider(
                      value: settings.speed.multiplier,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      label: '${settings.speed.multiplier.toStringAsFixed(2)}x',
                      onChanged: (val) => controller.updateSpeed(
                          val, settings.speed.pitchCorrectionEnabled),
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                title: const Text('Pitch Correction'),
                subtitle: const Text('Keep original pitch when changing speed'),
                value: settings.speed.pitchCorrectionEnabled,
                onChanged: (val) =>
                    controller.updateSpeed(settings.speed.multiplier, val),
              ),
              const Divider(),
              const _SectionHeader(title: 'Library & Data'),
              ListTile(
                leading: const Icon(PhosphorIconsRegular.folderNotchMinus),
                title: const Text('Manage Folders'),
                subtitle:
                    const Text('Add music folders or exclude directories'),
                trailing: const Icon(PhosphorIconsRegular.caretRight),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const FolderManagementScreen()));
                },
              ),
              ListTile(
                leading: const Icon(PhosphorIconsRegular.arrowsClockwise),
                title: const Text('Force Library Rescan'),
                subtitle: const Text(
                    'Check indexed folders for new or deleted files'),
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Scanning library...')));
                  final error = await controller.forceLibraryRefresh();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(error ?? 'Library scan complete.')));
                  }
                },
              ),
              ListTile(
                leading: const Icon(PhosphorIconsRegular.export),
                title: const Text('Export Backup'),
                subtitle: const Text(
                    'Create a backup of your library, playlists, and settings'),
                trailing: const Icon(PhosphorIconsRegular.caretRight),
                onTap: () => _showBackupDialog(context, ref),
              ),
              ListTile(
                leading: const Icon(PhosphorIconsRegular.downloadSimple),
                title: const Text('Restore Backup'),
                subtitle:
                    const Text('Restore from a previously exported backup'),
                trailing: const Icon(PhosphorIconsRegular.caretRight),
                onTap: () => _handleImportBackup(context, ref),
              ),
              const Divider(),
              const _SectionHeader(title: 'Appearance & Performance'),
              ListTile(
                leading: const Icon(PhosphorIconsRegular.palette),
                title: const Text('Theme'),
                subtitle: Text(prefs.themeMode.name.toUpperCase()),
                trailing: DropdownButton<AppThemeMode>(
                  value: prefs.themeMode,
                  underline: const SizedBox(),
                  items: AppThemeMode.values
                      .map((mode) =>
                          DropdownMenuItem(value: mode, child: Text(mode.name)))
                      .toList(),
                  onChanged: (mode) {
                    if (mode != null) {
                      ref
                          .read(appPreferencesProvider.notifier)
                          .updateTheme(mode);
                    }
                  },
                ),
              ),
              ListTile(
                leading: const Icon(PhosphorIconsRegular.gauge),
                title: const Text('Performance Profile'),
                subtitle: Text(prefs.performanceProfile.name.toUpperCase()),
                trailing: DropdownButton<PerformanceProfile>(
                  value: prefs.performanceProfile,
                  underline: const SizedBox(),
                  items: PerformanceProfile.values
                      .map((profile) => DropdownMenuItem(
                          value: profile, child: Text(profile.name)))
                      .toList(),
                  onChanged: (profile) {
                    if (profile != null) {
                      ref
                          .read(appPreferencesProvider.notifier)
                          .updateProfile(profile);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'Restart the app to fully apply RAM limits.'),
                          duration: Duration(seconds: 3)));
                    }
                  },
                ),
              ),
              const SizedBox(height: 32),
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
