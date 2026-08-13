import 'package:drift/drift.dart';

import '../../../core/error/failures.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/app_preferences.dart';
import '../app_database.dart';

class AppPreferencesMapper {
  const AppPreferencesMapper();

  Result<AppPreferences, Failure> toEntity(AppPreferencesRow row) {
    return AppPreferences.create(
      isOnboardingCompleted: row.isOnboardingCompleted,
      performanceProfile: row.performanceProfile,
      themeMode: row.themeMode,
    );
  }

  AppPreferencesTableCompanion toCompanion(AppPreferences entity) {
    return AppPreferencesTableCompanion.insert(
      id: const Value(0),
      isOnboardingCompleted: Value(entity.isOnboardingCompleted),
      performanceProfile: entity.performanceProfile,
      themeMode: entity.themeMode,
    );
  }
}