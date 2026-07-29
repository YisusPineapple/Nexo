import 'package:drift/drift.dart';

/// Persists at most one row: the [ActiveSessionSnapshot] used by
/// RestoreSessionUseCase. An EMPTY table (not a null-valued row) means
/// "no session yet" — mirrors [PlaybackRepository.getLastSession]'s
/// `Ok(null)` contract exactly. The repository implementation (2.3)
/// must treat a missing row as null, never write a sentinel row for
/// "no session".
@DataClassName('ActiveSessionRow')
class ActiveSessionTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(0))();
  TextColumn get activeQueueId => text()();
  IntColumn get positionMs => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
