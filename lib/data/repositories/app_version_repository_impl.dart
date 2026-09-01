import 'package:package_info_plus/package_info_plus.dart';

import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/app_version_info.dart';
import '../../domain/repositories/app_version_repository.dart';

class AppVersionRepositoryImpl implements AppVersionRepository {
  const AppVersionRepositoryImpl();

  @override
  Future<Result<AppVersionInfo, Failure>> getVersionInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return Ok(AppVersionInfo(
        version: info.version,
        buildNumber: info.buildNumber,
      ));
    } catch (e) {
      return Err(
        UnexpectedFailure('Failed to read app version info.', cause: e),
      );
    }
  }
}