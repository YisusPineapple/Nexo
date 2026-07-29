import 'package:drift/drift.dart';

import '../../../domain/entities/repeat_mode.dart';

class RepeatModeConverter extends TypeConverter<RepeatMode, String> {
  const RepeatModeConverter();

  @override
  RepeatMode fromSql(String fromDb) => RepeatMode.values.byName(fromDb);

  @override
  String toSql(RepeatMode value) => value.name;
}
