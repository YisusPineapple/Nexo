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

enum LyricsAlignment {
  left,
  center,
  right,
  justify,
}

enum LyricsFontSize {
  small,
  medium,
  large,
  extraLarge,
}

final class AppPreferences {
  const AppPreferences._({
    required this.isOnboardingCompleted,
    required this.performanceProfile,
    required this.themeMode,
    required this.lyricsAlignment,
    required this.lyricsFontSize,
    required this.lyricsBlurEnabled,
    required this.lyricsHighlightWords,
  });

  final bool isOnboardingCompleted;
  final PerformanceProfile performanceProfile;
  final AppThemeMode themeMode;
  final LyricsAlignment lyricsAlignment;
  final LyricsFontSize lyricsFontSize;
  final bool lyricsBlurEnabled;
  final bool lyricsHighlightWords;

  static const AppPreferences defaults = AppPreferences._(
    isOnboardingCompleted: false,
    performanceProfile: PerformanceProfile.balanced,
    themeMode: AppThemeMode.system,
    lyricsAlignment: LyricsAlignment.center,
    lyricsFontSize: LyricsFontSize.medium,
    lyricsBlurEnabled: true,
    lyricsHighlightWords: true,
  );

  static Result<AppPreferences, Failure> create({
    required bool isOnboardingCompleted,
    required PerformanceProfile performanceProfile,
    required AppThemeMode themeMode,
    LyricsAlignment lyricsAlignment = LyricsAlignment.center,
    LyricsFontSize lyricsFontSize = LyricsFontSize.medium,
    bool lyricsBlurEnabled = true,
    bool lyricsHighlightWords = true,
  }) {
    return Ok(AppPreferences._(
      isOnboardingCompleted: isOnboardingCompleted,
      performanceProfile: performanceProfile,
      themeMode: themeMode,
      lyricsAlignment: lyricsAlignment,
      lyricsFontSize: lyricsFontSize,
      lyricsBlurEnabled: lyricsBlurEnabled,
      lyricsHighlightWords: lyricsHighlightWords,
    ));
  }

  AppPreferences copyWith({
    bool? isOnboardingCompleted,
    PerformanceProfile? performanceProfile,
    AppThemeMode? themeMode,
    LyricsAlignment? lyricsAlignment,
    LyricsFontSize? lyricsFontSize,
    bool? lyricsBlurEnabled,
    bool? lyricsHighlightWords,
  }) {
    return AppPreferences._(
      isOnboardingCompleted:
          isOnboardingCompleted ?? this.isOnboardingCompleted,
      performanceProfile: performanceProfile ?? this.performanceProfile,
      themeMode: themeMode ?? this.themeMode,
      lyricsAlignment: lyricsAlignment ?? this.lyricsAlignment,
      lyricsFontSize: lyricsFontSize ?? this.lyricsFontSize,
      lyricsBlurEnabled: lyricsBlurEnabled ?? this.lyricsBlurEnabled,
      lyricsHighlightWords:
          lyricsHighlightWords ?? this.lyricsHighlightWords,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppPreferences &&
          other.isOnboardingCompleted == isOnboardingCompleted &&
          other.performanceProfile == performanceProfile &&
          other.themeMode == themeMode &&
          other.lyricsAlignment == lyricsAlignment &&
          other.lyricsFontSize == lyricsFontSize &&
          other.lyricsBlurEnabled == lyricsBlurEnabled &&
          other.lyricsHighlightWords == lyricsHighlightWords);

  @override
  int get hashCode => Object.hash(
        isOnboardingCompleted,
        performanceProfile,
        themeMode,
        lyricsAlignment,
        lyricsFontSize,
        lyricsBlurEnabled,
        lyricsHighlightWords,
      );
}