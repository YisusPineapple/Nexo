import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/app_version_info.dart';

/// Reads the app's own build identity (version + build number) as
/// reported by the platform. Kept as its own tiny repository rather
/// than folded into AppPreferencesRepository, because this is
/// read-only platform metadata with zero persistence — a fresh read
/// every time it's requested — while AppPreferencesRepository is
/// exclusively concerned with user-configurable, persisted state.
abstract interface class AppVersionRepository {
  Future<Result<AppVersionInfo, Failure>> getVersionInfo();
}