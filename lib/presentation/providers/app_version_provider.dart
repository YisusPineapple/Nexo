import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_version_info.dart';
import '../../domain/usecases/get_app_version_usecase.dart';
import '../../domain/usecases/use_case.dart';
import 'repository_providers.dart';

/// One-shot read of the app's own version — it never mutates during
/// the app's lifetime, so a plain FutureProvider is the right tool
/// here. Contrast with AppPreferencesNotifier, which needs update
/// methods (updateTheme, updateProfile, etc.) and therefore earns the
/// extra weight of a Notifier; this provider has nothing to mutate,
/// so an AsyncNotifier here would just be ceremony around one await.
final appVersionProvider = FutureProvider<AppVersionInfo>((ref) async {
  final useCase =
      GetAppVersionUseCase(ref.watch(appVersionRepositoryProvider));
  final result = await useCase.call(const NoParams());
  return result.when(
    ok: (info) => info,
    err: (failure) => throw failure,
  );
});