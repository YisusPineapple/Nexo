import 'package:drift/drift.dart';

@DataClassName('ExcludedFolderRow')
class ExcludedFolders extends Table {
  IntColumn get id => integer().autoIncrement()();
  
  /// The absolute path of the directory to ignore.
  /// Unique constraint prevents duplicate entries for the same folder.
  TextColumn get path => text().unique()();
}