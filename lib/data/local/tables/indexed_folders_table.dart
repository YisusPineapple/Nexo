import 'package:drift/drift.dart';

@DataClassName('IndexedFolderRow')
class IndexedFolders extends Table {
  TextColumn get path => text()();
  IntColumn get dateAddedUtcMs => integer()();

  @override
  Set<Column> get primaryKey => {path};
}