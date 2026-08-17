import 'package:drift/drift.dart';
import '../../../domain/entities/app_preferences.dart';

class LyricsAlignmentConverter extends TypeConverter<LyricsAlignment, String> {
  const LyricsAlignmentConverter();

  @override
  LyricsAlignment fromSql(String fromDb) => LyricsAlignment.values.byName(fromDb);

  @override
  String toSql(LyricsAlignment value) => value.name;
}