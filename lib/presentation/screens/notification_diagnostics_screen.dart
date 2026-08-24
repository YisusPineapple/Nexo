import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class NotificationDiagnosticsScreen extends StatefulWidget {
  const NotificationDiagnosticsScreen({super.key});

  @override
  State<NotificationDiagnosticsScreen> createState() =>
      _NotificationDiagnosticsScreenState();
}

class _NotificationDiagnosticsScreenState
    extends State<NotificationDiagnosticsScreen> {
  static const _channel =
      MethodChannel('io.github.yisus.nexo/notification_diagnostics');

  Map<Object?, Object?>? _result;
  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    if (!Platform.isAndroid) {
      setState(() {
        _error = 'This diagnostic screen only applies to Android.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'getNotificationDiagnostics',
      );
      setState(() {
        _result = raw;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to read diagnostics: $e';
        _isLoading = false;
      });
    }
  }

  String _diagnosisSummary(Map<Object?, Object?> r) {
    final appLevelEnabled = r['appLevelNotificationsEnabled'] as bool? ?? false;
    final channelExists = r['channelExists'] as bool? ?? false;
    final channelImportanceValue = r['channelImportanceValue'] as int?;
    final hasActiveNotification =
        r['hasActiveAudioChannelNotification'] as bool? ?? false;

    if (!appLevelEnabled) {
      return 'The OS reports notifications as DISABLED for this app at '
          'the system level, regardless of what the visual toggles show. '
          'This points to an AppOps-level block (common on Transsion/HiOS) '
          'rather than a code bug.';
    }
    if (channelExists && channelImportanceValue == 0) {
      return 'The audio playback channel exists but its importance is '
          'NONE — the system is blocking it at the channel level. Apps '
          'cannot change channel importance themselves; this needs to be '
          'reset from the system notification settings for this app.';
    }
    if (!channelExists) {
      return 'The notification channel has not been created yet. '
          'audio_service has not attempted to post a notification at '
          'all yet — press Play, then tap refresh again.';
    }
    if (!hasActiveNotification) {
      return 'The channel is healthy and enabled, but Android has NO '
          'active notification posted from it right now. This points to '
          'the foreground-service promotion itself failing or being '
          'rejected (a timing issue) — not a permission problem.';
    }
    return 'Android reports the notification as ACTIVE and POSTED right '
        'now. If it is still not visible in the status bar, HiOS is '
        'suppressing an already-valid notification at the render layer — '
        'almost certainly an "Autostart" / "Protected apps" restriction, '
        'not something fixable from app code alone.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.arrowsClockwise),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _runDiagnostics,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!),
                  )
                : _result == null
                    ? const Center(child: Text('No data yet.'))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Card(
                            color: theme.colorScheme.primaryContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                _diagnosisSummary(_result!),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Play a song first, THEN tap refresh, to catch '
                            'the state right after the foreground service '
                            'is supposed to start.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: SelectableText(
                                _result!.entries
                                    .map((e) => '${e.key}: ${e.value}')
                                    .join('\n'),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy raw data'),
                              onPressed: () {
                                final text = _result!.entries
                                    .map((e) => '${e.key}: ${e.value}')
                                    .join('\n');
                                Clipboard.setData(ClipboardData(text: text));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Copied to clipboard.'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }
}