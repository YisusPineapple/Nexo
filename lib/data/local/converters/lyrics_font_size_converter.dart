import 'package:drift/drift.dart';
import '../../../domain/entities/app_preferences.dart';

class LyricsFontSizeConverter extends TypeConverter<LyricsFontSize, String> {
  const LyricsFontSizeConverter();

  @override
  LyricsFontSize fromSql(String fromDb) =>
      LyricsFontSize.values.byName(fromDb);

  @override
  String toSql(LyricsFontSize value) => value.name;
}