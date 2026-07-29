import 'package:drift/drift.dart';

import '../../../domain/entities/crossfade_config.dart';

class CrossfadeModeConverter extends TypeConverter<CrossfadeMode, String> {
  const CrossfadeModeConverter();

  @override
  CrossfadeMode fromSql(String fromDb) => CrossfadeMode.values.byName(fromDb);

  @override
  String toSql(CrossfadeMode value) => value.name;
}
