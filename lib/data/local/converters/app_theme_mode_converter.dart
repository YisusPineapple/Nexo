import 'package:drift/drift.dart';
import '../../../domain/entities/app_preferences.dart';

class AppThemeModeConverter extends TypeConverter<AppThemeMode, String> {
  const AppThemeModeConverter();

  @override
  AppThemeMode fromSql(String fromDb) => AppThemeMode.values.byName(fromDb);

  @override
  String toSql(AppThemeMode value) => value.name;
}