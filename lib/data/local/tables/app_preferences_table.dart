import 'package:drift/drift.dart';
import '../converters/app_theme_mode_converter.dart';
import '../converters/lyrics_alignment_converter.dart';
import '../converters/lyrics_font_size_converter.dart';
import '../converters/performance_profile_converter.dart';

@DataClassName('AppPreferencesRow')
class AppPreferencesTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  
  BoolColumn get isOnboardingCompleted =>
      boolean().withDefault(const Constant(false))();
  TextColumn get performanceProfile =>
      text().map(const PerformanceProfileConverter())();
  TextColumn get themeMode => text().map(const AppThemeModeConverter())();
  TextColumn get lyricsAlignment => text()
      .map(const LyricsAlignmentConverter())
      .withDefault(const Constant('center'))();
  TextColumn get lyricsFontSize => text()
      .map(const LyricsFontSizeConverter())
      .withDefault(const Constant('medium'))();
  BoolColumn get lyricsBlurEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get lyricsHighlightWords =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}