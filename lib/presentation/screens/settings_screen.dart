import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../domain/entities/app_preferences.dart';
import '../../domain/entities/crossfade_config.dart';
import '../providers/app_preferences_provider.dart';
import '../providers/backup_providers.dart';
import '../providers/settings_providers.dart';
import 'equalizer_screen.dart';
import 'library/folder_management_screen.dart';
import 'notification_diagnostics_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _executeBackup(
    BuildContext loadingCtx,
    BuildContext mainCtx,
    WidgetRef ref,
    bool includeLibrary,
    bool includePlaylists,
    bool includeSettings,
    String destinationDirectory,
  ) async {
    final backupPath = await ref.read(backupControllerProvider).createBackup(
          includeLibrary: includeLibrary,
          includePlaylists: includePlaylists,
          includeSettings: includeSettings,
          destinationDirectory: destinationDirectory,
        );

    if (loadingCtx.mounted) {
      Navigator.pop(loadingCtx);
    }

    if (!mainCtx.mounted) return;

    if (backupPath == null) {
      ScaffoldMessenger.of(mainCtx).showSnackBar(
        const SnackBar(content: Text('Backup creation failed.')),
      );
    } else {
      ScaffoldMessenger.of(mainCtx).showSnackBar(
        SnackBar(content: Text('Backup saved to: $backupPath')),
      );
    }
  }

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
      builder: (dialogCtx) => StatefulBuilder(
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
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogCtx);

                unawaited(
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (loadingCtx) {
                      unawaited(_executeBackup(
                        loadingCtx,
                        context,
                        ref,
                        includeLibrary,
                        includePlaylists,
                        includeSettings,
                        destinationDirectory,
                      ));

                      return const AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Creating backup...'),
                            SizedBox(height: 8),
                            Text(
                              'This may take a few minutes depending on your library size.',
                              style: TextStyle(
                                  fontSize: 12, fontStyle: FontStyle.italic),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
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
        builder: (loadingCtx) {
          unawaited(_executeRestore(loadingCtx, context, ref, path));
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Restoring backup...'),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _executeRestore(
    BuildContext loadingCtx,
    BuildContext mainCtx,
    WidgetRef ref,
    String path,
  ) async {
    final error = await ref.read(backupControllerProvider).restoreBackup(path);

    if (loadingCtx.mounted) {
      Navigator.pop(loadingCtx);
    }

    if (!mainCtx.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(mainCtx).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      await SystemNavigator.pop();
      exit(0);
    }
  }

  String _getCrossfadeLabel(CrossfadeMode mode) {
    switch (mode) {
      case CrossfadeMode.disabled: return 'DISABLED';
      case CrossfadeMode.fixed: return 'MANUAL';
      case CrossfadeMode.intelligent: return 'AUTO';
      case CrossfadeMode.autoMix: return 'AUTOMIX';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(playbackSettingsProvider);
    final prefs = ref.watch(appPreferencesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
      ),
      body: settingsAsync.when(
        data: (settings) {
          final controller = ref.read(settingsControllerProvider);
          
          CrossfadeMode effectiveMode = settings.crossfade.mode;
          if (effectiveMode == CrossfadeMode.autoMix) {
            effectiveMode = CrossfadeMode.intelligent;
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              _SettingsGroup(
                title: 'Audio Engine',
                children: [
                  ListTile(
                    leading: const Icon(PhosphorIconsRegular.slidersHorizontal),
                    title: const Text('Equalizer'),
                    subtitle: const Text('10-band EQ and presets'),
                    trailing:
                        const Icon(PhosphorIconsRegular.caretRight, size: 16),
                    onTap: () {
                      unawaited(Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const EqualizerScreen())));
                    },
                  ),
                  const _GroupDivider(),
                  ListTile(
                    leading: const Icon(PhosphorIconsRegular.waveSine),
                    title: const Text('Crossfade Mode'),
                    subtitle: Text(_getCrossfadeLabel(effectiveMode)),
                    trailing: DropdownButton<CrossfadeMode>(
                      value: effectiveMode,
                      underline: const SizedBox(),
                      icon: const Icon(PhosphorIconsRegular.caretDown, size: 16),
                      items: [CrossfadeMode.disabled, CrossfadeMode.fixed, CrossfadeMode.intelligent]
                          .map((mode) => DropdownMenuItem(
                              value: mode, child: Text(_getCrossfadeLabel(mode))))
                          .toList(),
                      onChanged: (mode) {
                        if (mode != null) {
                          unawaited(controller.updateCrossfade(
                              mode, settings.crossfade.duration,
                              isAutoDuration: mode == CrossfadeMode.intelligent));
                        }
                      },
                    ),
                  ),
                  if (effectiveMode == CrossfadeMode.fixed) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Crossfade Duration: ${settings.crossfade.duration.inSeconds}s'),
                          Slider(
                            value: settings.crossfade.duration.inSeconds
                                .toDouble(),
                            min: 0,
                            max: 12,
                            divisions: 12,
                            label:
                                '${settings.crossfade.duration.inSeconds}s',
                            onChanged: (val) => unawaited(
                                controller.updateCrossfade(
                                    CrossfadeMode.fixed,
                                    Duration(seconds: val.toInt()),
                                    isAutoDuration: false)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (effectiveMode == CrossfadeMode.intelligent) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(56, 0, 16, 16),
                      child: Text(
                          'The system will automatically choose the optimal duration based on silence.',
                          style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic)),
                    ),
                  ],
                  const _GroupDivider(),
                  ListTile(
                    leading: const Icon(PhosphorIconsRegular.gauge),
                    title: const Text('Playback Speed'),
                    subtitle: Text(
                        '${settings.speed.multiplier.toStringAsFixed(2)}x'),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(56, 0, 16, 8),
                    child: Slider(
                      value: settings.speed.multiplier,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      label: '${settings.speed.multiplier.toStringAsFixed(2)}x',
                      onChanged: (val) => unawaited(controller.updateSpeed(
                          val, settings.speed.pitchCorrectionEnabled)),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.only(left: 56, right: 16),
                    title: const Text('Pitch Correction'),
                    subtitle:
                        const Text('Keep original pitch when changing speed'),
                    value: settings.speed.pitchCorrectionEnabled,
                    onChanged: (val) => unawaited(controller.updateSpeed(
                        settings.speed.multiplier, val)),
                  ),
                ],
              ),
              _SettingsGroup(
                title: 'Lyrics & Display',
                children: [
                  ListTile(
                    leading: const Icon(PhosphorIconsRegular.textAlignCenter),
                    title: const Text('Lyrics Alignment'),
                    trailing: DropdownButton<LyricsAlignment>(
                      value: prefs.lyricsAlignment,
                      underline: const SizedBox(),
                      icon:
                          const Icon(PhosphorIconsRegular.caretDown, size: 16),
                      items: LyricsAlignment.values
                          .map((align) => DropdownMenuItem(
                              value: align,
                              child: Text(align.name.toUpperCase())))
                          .toList(),
                      onChanged: (align) {
                        if (align != null) {
                          unawaited(ref
                              .read(appPreferencesProvider.notifier)
                              .updateLyricsAlignment(align));
                        }
                      },
                    ),
                  ),
                  const _GroupDivider(),
                  ListTile(
                    leading: const Icon(PhosphorIconsRegular.textT),
                    title: const Text('Lyrics Font Size'),
                    trailing: DropdownButton<LyricsFontSize>(
                      value: prefs.lyricsFontSize,
                      underline: const SizedBox(),
                      icon:
                          const Icon(PhosphorIconsRegular.caretDown, size: 16),
                      items: LyricsFontSize.values
                          .map((size) => DropdownMenuItem(
                              value: size,
                              child: Text(size.name.toUpperCase())))
                          .toList(),
                      onChanged: (size) {
                        if (size != null) {
                          unawaited(ref
                              .read(appPreferencesProvider.notifier)
                              .updateLyricsFontSize(size));
                        }
                      },
                    ),
                  ),
                  const _GroupDivider(),
                  SwitchListTile(
                    secondary: const Icon(PhosphorIconsRegular.sparkle),
                    title: const Text('3D Depth & Blur Effect'),
                    subtitle: const Text(
                        'Blurs inactive lyric lines. Disable on older hardware for maximum FPS'),
                    value: prefs.lyricsBlurEnabled,
                    onChanged: (val) => unawaited(ref
                        .read(appPreferencesProvider.notifier)
                        .toggleLyricsBlur(val)),
                  ),
                  const _GroupDivider(),
                  SwitchListTile(
                    secondary: const Icon(PhosphorIconsRegular.textAa),
                    title: const Text('Word-by-Word Sync'),
                    subtitle: const Text(
                        'Highlights individual syllables when available in Enhanced LRC'),
                    value: prefs.lyricsHighlightWords,
                    onChanged: (val) => unawaited(ref
                        .read(appPreferencesProvider.notifier)
                        .toggleLyricsHighlightWords(val)),
                  ),
                ],
              ),
              _SettingsGroup(
                title: 'Library & Data',
                children: [
                  ListTile(
                    leading: const Icon(PhosphorIconsRegular.folderNotchMinus),
                    title: const Text('Manage Folders'),
                    subtitle:
                        const Text('Add music folders or exclude directories'),
                    trailing:
                        const Icon(PhosphorIconsRegular.caretRight, size: 16),
                    onTap: () {
                      unawaited(Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const FolderManagementScreen())));
                    },
                  ),
                  const _GroupDivider(),
                  ListTile(
                    leading: const Icon(PhosphorIconsRegular.arrowsClockwise),
                    title: const Text('Force Library Rescan'),
                    subtitle: const Text(
                        'Check indexed folders for new or deleted files'),
                    onTap: () async {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              'Scan started. Check Library tab for progress.')));
                      await controller.forceLibraryRefresh();
                    },
                  ),
                  const _GroupDivider(),
                  ListTile(
                    leading: const Icon(PhosphorIconsRegular.export),
                    title: const Text('Export Backup'),
                    subtitle: const Text(
                        'Create a backup of your library, playlists, and settings'),
                    trailing:
                        const Icon(PhosphorIconsRegular.caretRight, size: 16),
                    onTap: () => unawaited(_showBackupDialog(context, ref)),
                  ),
                  const _GroupDivider(),
                  ListTile(
                    leading: const Icon(PhosphorIconsRegular.downloadSimple),
                    title: const Text('Restore Backup'),
                    subtitle: const Text(
                        'Restore from a previously exported backup'),
                    trailing:
                        const Icon(PhosphorIconsRegular.caretRight, size: 16),
                    onTap: () => unawaited(_handleImportBackup(context, ref)),
                  ),
                ],
              ),
              _SettingsGroup(
                title: 'Appearance & Performance',
                children: [
                  ListTile(
                    leading: const Icon(PhosphorIconsRegular.palette),
                    title: const Text('Theme'),
                    trailing: DropdownButton<AppThemeMode>(
                      value: prefs.themeMode,
                      underline: const SizedBox(),
                      icon:
                          const Icon(PhosphorIconsRegular.caretDown, size: 16),
                      items: AppThemeMode.values
                          .map((mode) => DropdownMenuItem(
                              value: mode, child: Text(mode.name)))
                          .toList(),
                      onChanged: (mode) {
                        if (mode != null) {
                          unawaited(ref
                              .read(appPreferencesProvider.notifier)
                              .updateTheme(mode));
                        }
                      },
                    ),
                  ),
                  const _GroupDivider(),
                  ListTile(
                    leading: const Icon(PhosphorIconsRegular.cpu),
                    title: const Text('Performance Profile'),
                    trailing: DropdownButton<PerformanceProfile>(
                      value: prefs.performanceProfile,
                      underline: const SizedBox(),
                      icon:
                          const Icon(PhosphorIconsRegular.caretDown, size: 16),
                      items: PerformanceProfile.values
                          .map((profile) => DropdownMenuItem(
                              value: profile, child: Text(profile.name)))
                          .toList(),
                      onChanged: (profile) {
                        if (profile != null) {
                          unawaited(ref
                              .read(appPreferencesProvider.notifier)
                              .updateProfile(profile));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Restart the app to fully apply RAM limits.'),
                                  duration: Duration(seconds: 3)));
                        }
                      },
                    ),
                  ),
                ],
              ),
              _SettingsGroup(
                title: 'System & Permissions',
                children: [
                  if (Platform.isAndroid) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Text(
                        'If the player notification does not appear, your device manufacturer (like Tecno, Xiaomi, or Oppo) might be restricting background execution.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(PhosphorIconsRegular.batteryWarning),
                      title: const Text('Disable Battery Restrictions'),
                      trailing: const Icon(PhosphorIconsRegular.caretRight, size: 16),
                      onTap: () async {
                        final success = await controller.requestBatteryOptimizationExemption();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(success ? 'Exemption granted' : 'Exemption denied or already granted')),
                          );
                        }
                      },
                    ),
                    const _GroupDivider(),
                    ListTile(
                      leading: const Icon(PhosphorIconsRegular.rocketLaunch),
                      title: const Text('Open Autostart Settings'),
                      subtitle: const Text('Allow Nexo to run in the background'),
                      trailing: const Icon(PhosphorIconsRegular.arrowSquareOut, size: 16),
                      onTap: () async {
                        final success = await controller.openAutostartSettings();
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not open Autostart settings automatically.')),
                          );
                        }
                      },
                    ),
                    const _GroupDivider(),
                  ],
                  ListTile(
                    leading: const Icon(PhosphorIconsRegular.bellRinging),
                    title: const Text('Notification Access'),
                    subtitle: const Text(
                        'Configure lockscreen & playback controls in Android settings'),
                    trailing:
                        const Icon(PhosphorIconsRegular.arrowSquareOut, size: 16),
                    onTap: () async {
                      await openAppSettings();
                    },
                  ),
                  const _GroupDivider(),
                  ListTile(
                    leading: const Icon(PhosphorIconsRegular.info),
                    title: const Text('Notification Diagnostics'),
                    subtitle: const Text(
                        'Check the real notification state without ADB'),
                    trailing:
                        const Icon(PhosphorIconsRegular.caretRight, size: 16),
                    onTap: () {
                      unawaited(Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              const NotificationDiagnosticsScreen())));
                    },
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text(
                    'Nexo Music Player\nVersion 0.0.10-beta+34',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
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

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupDivider extends StatelessWidget {
  const _GroupDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color:
          Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }
}
