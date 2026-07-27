import 'package:test/test.dart';
import 'package:nexo/domain/usecases/refresh_library_usecase.dart';
import 'package:nexo/domain/usecases/use_case.dart';

import '../repositories/fakes/fake_song_repository.dart';

void main() {
  group('RefreshLibraryUseCase', () {
    test('delegates to the repository refresh', () async {
      final repo = FakeSongRepository();
      final useCase = RefreshLibraryUseCase(repo);

      final result = await useCase.call(const NoParams());

      expect(result.isOk, isTrue);
    });

    test('propagates a failure surfaced by the repository', () async {
      final repo = FakeSongRepository()..failIndexing = true;
      final useCase = RefreshLibraryUseCase(repo);

      final result = await useCase.call(const NoParams());

      expect(result.isErr, isTrue);
    });
  });
}
