import 'package:drift/drift.dart';
import '../../../domain/entities/app_preferences.dart';

class PerformanceProfileConverter extends TypeConverter<PerformanceProfile, String> {
  const PerformanceProfileConverter();

  @override
  PerformanceProfile fromSql(String fromDb) => PerformanceProfile.values.byName(fromDb);

  @override
  String toSql(PerformanceProfile value) => value.name;
}