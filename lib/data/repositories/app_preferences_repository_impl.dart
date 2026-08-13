import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/app_preferences.dart';
import '../../domain/repositories/app_preferences_repository.dart';
import '../local/app_database.dart';
import '../local/mappers/app_preferences_mapper.dart';

class AppPreferencesRepositoryImpl implements AppPreferencesRepository {
  AppPreferencesRepositoryImpl(
    this._db, {
    AppPreferencesMapper mapper = const AppPreferencesMapper(),
  }) : _mapper = mapper;

  final AppDatabase _db;
  final AppPreferencesMapper _mapper;

  @override
  Future<Result<AppPreferences, Failure>> getPreferences() async {
    try {
      final rows = await _db.select(_db.appPreferencesTable).get();
      if (rows.isEmpty) {
        return const Ok(AppPreferences.defaults);
      }
      return _mapper.toEntity(rows.first);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to fetch app preferences.', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> savePreferences(AppPreferences preferences) async {
    try {
      await _db.into(_db.appPreferencesTable).insertOnConflictUpdate(
            _mapper.toCompanion(preferences),
          );
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure('Failed to save app preferences.', cause: e));
    }
  }
}