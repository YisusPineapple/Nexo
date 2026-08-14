// lib/presentation/providers/app_preferences_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_preferences.dart';
import 'repository_providers.dart';

final appPreferencesProvider =
    NotifierProvider<AppPreferencesNotifier, AppPreferences>(
  AppPreferencesNotifier.new,
);

class AppPreferencesNotifier extends Notifier<AppPreferences> {
  AppPreferencesNotifier([this._initialPrefs]);
  final AppPreferences? _initialPrefs;

  @override
  AppPreferences build() {
    // Dart 3.2+ promotes final fields after null-check,
    // so no '!' is needed here.
    if (_initialPrefs != null) return _initialPrefs;
    return AppPreferences.defaults;
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