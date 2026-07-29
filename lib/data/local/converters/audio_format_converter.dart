import 'package:drift/drift.dart';

import '../../../domain/entities/audio_format.dart';

/// Maps [AudioFormat] to its enum name as TEXT. Stored as text, not
/// int index, so the column stays human-readable in the raw .db file
/// during debugging and survives a future reordering of
/// [AudioFormat]'s enum values without silently corrupting existing
/// rows (an int-index converter would NOT survive that).
class AudioFormatConverter extends TypeConverter<AudioFormat, String> {
  const AudioFormatConverter();

  @override
  AudioFormat fromSql(String fromDb) => AudioFormat.values.byName(fromDb);

  @override
  String toSql(AudioFormat value) => value.name;
}
