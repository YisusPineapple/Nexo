import 'package:drift/drift.dart';

@DataClassName('PlaylistRow')
class Playlists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get dateCreatedUtcMs => integer()();

  @override
  Set<Column> get primaryKey => {id};
}