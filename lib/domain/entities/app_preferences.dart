import '../../core/error/failures.dart';
import '../../core/utils/result.dart';

enum PerformanceProfile {
  vivo,
  balanced,
  eco,
  custom,
}

enum AppThemeMode {
  light,
  dark,
  system,
}

final class AppPreferences {
  const AppPreferences._({
    required this.isOnboardingCompleted,
    required this.performanceProfile,
    required this.themeMode,
  });

  final bool isOnboardingCompleted;
  final PerformanceProfile performanceProfile;
  final AppThemeMode themeMode;

  static const AppPreferences defaults = AppPreferences._(
    isOnboardingCompleted: false,
    performanceProfile: PerformanceProfile.balanced,
    themeMode: AppThemeMode.system,
  );

  static Result<AppPreferences, Failure> create({
    required bool isOnboardingCompleted,
    required PerformanceProfile performanceProfile,
    required AppThemeMode themeMode,
  }) {
    return Ok(AppPreferences._(
      isOnboardingCompleted: isOnboardingCompleted,
      performanceProfile: performanceProfile,
      themeMode: themeMode,
    ));
  }

  AppPreferences copyWith({
    bool? isOnboardingCompleted,
    PerformanceProfile? performanceProfile,
    AppThemeMode? themeMode,
  }) {
    return AppPreferences._(
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
      performanceProfile: performanceProfile ?? this.performanceProfile,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppPreferences &&
          other.isOnboardingCompleted == isOnboardingCompleted &&
          other.performanceProfile == performanceProfile &&
          other.themeMode == themeMode);

  @override
  int get hashCode => Object.hash(
        isOnboardingCompleted,
        performanceProfile,
        themeMode,
      );
}