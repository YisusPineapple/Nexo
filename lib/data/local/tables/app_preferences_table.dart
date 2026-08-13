import 'package:drift/drift.dart';
import '../converters/app_theme_mode_converter.dart';
import '../converters/performance_profile_converter.dart';

@DataClassName('AppPreferencesRow')
class AppPreferencesTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  
  BoolColumn get isOnboardingCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get performanceProfile => text().map(const PerformanceProfileConverter())();
  TextColumn get themeMode => text().map(const AppThemeModeConverter())();

  @override
  Set<Column> get primaryKey => {id};
}