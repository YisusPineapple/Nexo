import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/app_preferences.dart';

abstract interface class AppPreferencesRepository {
  Future<Result<AppPreferences, Failure>> getPreferences();
  Future<Result<void, Failure>> savePreferences(AppPreferences preferences);
}