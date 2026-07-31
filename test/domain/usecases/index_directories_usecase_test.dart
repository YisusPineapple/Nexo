import 'package:flutter_test/flutter_test.dart';
import 'package:nexo/core/error/failures.dart';
import 'package:nexo/domain/usecases/index_directories_usecase.dart';

import '../repositories/fakes/fake_song_repository.dart';

void main() {
  group('IndexDirectoriesUseCase', () {
    test('delegates to the repository for a valid, unique path list', () async {
      final repo = FakeSongRepository();
      final useCase = IndexDirectoriesUseCase(repo);

      final result = await useCase.call(['/music/rock', '/music/jazz']);

      expect(result.isOk, isTrue);
      expect(repo.indexDirectoriesCallCount, 1);
    });

    test('rejects an empty path list without reaching the repository',
        () async {
      final repo = FakeSongRepository();
      final useCase = IndexDirectoriesUseCase(repo);

      final result = await useCase.call(const []);

      expect(
        result.when(ok: (_) => null, err: (e) => e),
        isA<ValidationFailure>(),
      );
      expect(repo.indexDirectoriesCallCount, 0);
    });

    test('rejects a path list containing an empty string', () async {
      final repo = FakeSongRepository();
      final useCase = IndexDirectoriesUseCase(repo);

      final result = await useCase.call(['/music/rock', '']);

      expect(
        result.when(ok: (_) => null, err: (e) => e),
        isA<ValidationFailure>(),
      );
      expect(repo.indexDirectoriesCallCount, 0);
    });

    test(
        'rejects a path list with exact duplicates without reaching '
        'the repository', () async {
      final repo = FakeSongRepository();
      final useCase = IndexDirectoriesUseCase(repo);

      final result = await useCase.call(['/music/rock', '/music/rock']);

      expect(
        result.when(ok: (_) => null, err: (e) => e),
        isA<ValidationFailure>(),
      );
      expect(repo.indexDirectoriesCallCount, 0);
    });

    test('propagates a failure surfaced by the repository', () async {
      final repo = FakeSongRepository()..failIndexing = true;
      final useCase = IndexDirectoriesUseCase(repo);

      final result = await useCase.call(['/music']);

      expect(result.isErr, isTrue);
      expect(repo.indexDirectoriesCallCount, 1);
    });
  });
}
