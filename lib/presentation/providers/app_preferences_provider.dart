import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_preferences.dart';
import 'repository_providers.dart';

final appPreferencesProvider = NotifierProvider<AppPreferencesNotifier, AppPreferences>(
  AppPreferencesNotifier.new,
);

class AppPreferencesNotifier extends Notifier<AppPreferences> {
  AppPreferencesNotifier([this._initialPrefs]);
  
  final AppPreferences? _initialPrefs;

  @override
  AppPreferences build() {
    if (_initialPrefs != null) return _initialPrefs; // <-- Eliminado el '!'
    throw UnimplementedError('appPreferencesProvider must be overridden in main()');
  }

  Future<void> updateProfile(PerformanceProfile profile) async {
    final updated = state.copyWith(performanceProfile: profile);
    await _save(updated);
  }

  Future<void> updateTheme(AppThemeMode theme) async {
    final updated = state.copyWith(themeMode: theme);
    await _save(updated);
  }

  Future<void> completeOnboarding() async {
    final updated = state.copyWith(isOnboardingCompleted: true);
    await _save(updated);
  }

  Future<void> _save(AppPreferences prefs) async {
    state = prefs;
    await ref.read(appPreferencesRepositoryProvider).savePreferences(prefs);
  }
}