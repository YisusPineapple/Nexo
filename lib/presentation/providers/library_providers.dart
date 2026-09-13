import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/song.dart';
import '../../domain/entities/song_sort_option.dart';
import '../../domain/usecases/get_all_songs_usecase.dart';
import '../../domain/usecases/index_directories_usecase.dart';
import '../../domain/usecases/refresh_library_usecase.dart';
import '../../domain/usecases/search_library_usecase.dart';
import '../../domain/usecases/search_songs_usecase.dart';
import '../../domain/usecases/use_case.dart';
import '../../core/utils/result_extensions.dart';
import 'repository_providers.dart';

class SortConfig<T> {
  const SortConfig(this.option, {this.isAscending = true});
  final T option;
  final bool isAscending;

  SortConfig<T> copyWith({T? option, bool? isAscending}) {
    return SortConfig<T>(
      option ?? this.option,
      isAscending: isAscending ?? this.isAscending,
    );
  }
}

final songSearchQueryProvider = StateProvider<String>((ref) => '');
final globalSearchQueryProvider = StateProvider<String>((ref) => '');

final songSortProvider = StateProvider<SortConfig<SongSortOption>>(
    (ref) => const SortConfig(SongSortOption.title));

final _getAllSongsUseCaseProvider = Provider<GetAllSongsUseCase>((ref) {
  return GetAllSongsUseCase(ref.watch(songRepositoryProvider));
});

final _searchSongsUseCaseProvider = Provider<SearchSongsUseCase>((ref) {
  return SearchSongsUseCase(ref.watch(songRepositoryProvider));
});

final _searchLibraryUseCaseProvider = Provider<SearchLibraryUseCase>((ref) {
  return SearchLibraryUseCase(ref.watch(songRepositoryProvider));
});

final _indexDirectoriesUseCaseProvider =
    Provider<IndexDirectoriesUseCase>((ref) {
  return IndexDirectoriesUseCase(ref.watch(songRepositoryProvider));
});

final _refreshLibraryUseCaseProvider = Provider<RefreshLibraryUseCase>((ref) {
  return RefreshLibraryUseCase(ref.watch(songRepositoryProvider));
});

// NOTE: the previous `coversUpdatedProvider` was removed in Sprint 9 / T2.
// It wrapped `SongRepository.coversUpdatedStream`, a broadcast StreamController
// whose only emit site (`_coversUpdatedController.add(null)`) was never
// actually invoked — a dead reactive pipe. Cover reactivity is now provided
// natively by Drift via `watchSongsWindow` over `_db.songs` (see
// Sprint9_P0_T2.md §2.7). This provider existed only as the vestigial
// invalidation signal inside `sortedSongsProvider` and is not replaced.

// FIX: Fast, clean FutureProvider connected to UseCases respecting Clean
// Architecture. Rebuilds declaratively when sorting or search query changes.
// (Pre-T2 name kept for the grouped-library screens that still consume it —
// see Sprint9_P0_T2.md §9. SongsScreen migrates off this in commit 4 of T2.)
final sortedSongsProvider = FutureProvider<List<Song>>((ref) async {
  final query = ref.watch(songSearchQueryProvider);
  final sortConfig = ref.watch(songSortProvider);

  final result = query.isEmpty
      ? await ref.watch(_getAllSongsUseCaseProvider).call((
          sortOption: sortConfig.option,
          isAscending: sortConfig.isAscending,
        ))
      : await ref.watch(_searchSongsUseCaseProvider).call((
          query: query,
          sortOption: sortConfig.option,
          isAscending: sortConfig.isAscending,
        ));

  return result.unwrapOrThrow();
});

final globalSearchResultsProvider =
    FutureProvider<SearchLibraryResult>((ref) async {
  final query = ref.watch(globalSearchQueryProvider);
  if (query.isEmpty) {
    return const (
      songs: <Song>[],
      artists: <String>[],
      albums: <String>[],
    );
  }

  final result = await ref.watch(_searchLibraryUseCaseProvider).call(query);
  return result.unwrapOrThrow();
});

typedef IndexingProgress = ({int current, int total});

final indexDirectoriesControllerProvider =
    AsyncNotifierProvider<IndexDirectoriesController, IndexingProgress?>(
  IndexDirectoriesController.new,
);

class IndexDirectoriesController extends AsyncNotifier<IndexingProgress?> {
  @override
  Future<IndexingProgress?> build() async => null;

  Future<void> indexDirectory(String path) async {
    state = const AsyncData(null);

    final result = await ref.read(_indexDirectoriesUseCaseProvider).call(
      [path],
      onProgress: (current, total) {
        state = AsyncData((current: current, total: total));
      },
    );

    state = result.when(
      ok: (_) {
        ref.invalidate(sortedSongsProvider);
        return const AsyncData(null);
      },
      err: (failure) => AsyncValue<IndexingProgress?>.error(
        failure,
        StackTrace.current,
      ),
    );
  }

  Future<void> refreshLibrary() async {
    state = const AsyncData(null);

    final result = await ref.read(_refreshLibraryUseCaseProvider).call(
      const NoParams(),
      onProgress: (current, total) {
        state = AsyncData((current: current, total: total));
      },
    );

    state = result.when(
      ok: (_) {
        ref.invalidate(sortedSongsProvider);
        return const AsyncData(null);
      },
      err: (failure) => AsyncValue<IndexingProgress?>.error(
        failure,
        StackTrace.current,
      ),
    );
  }
}
