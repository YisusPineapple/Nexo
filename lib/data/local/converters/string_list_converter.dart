import 'package:drift/drift.dart';

/// Stores [Song.genreNames] (a `List<String>`, since ID3v2.4/Vorbis
/// both allow repeated genre tags) as one delimited TEXT column.
///
/// A normalized join table would be the "proper" relational shape,
/// but [SongRepository] has no genre-based query today (see that
/// contract's own docstring on why Artist/Album/Genre aren't
/// first-class yet) — this stays a single column until a real
/// "songs by genre" use case actually needs to query by it. If that
/// day comes, this is a schema migration, not a Domain change.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  /// ASCII Unit Separator — not a character any real ID3/Vorbis genre
  /// tag will legitimately contain, unlike a comma or semicolon.
  static const _separator = '\u001F';

  @override
  List<String> fromSql(String fromDb) =>
      fromDb.isEmpty ? const [] : fromDb.split(_separator);

  @override
  String toSql(List<String> value) => value.join(_separator);
}
