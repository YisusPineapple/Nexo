import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/song.dart';
import '../../domain/usecases/get_all_songs_usecase.dart';
import '../../domain/usecases/index_directories_usecase.dart';
import '../../domain/usecases/refresh_library_usecase.dart';
import '../../domain/usecases/search_songs_usecase.dart';
import '../../domain/usecases/use_case.dart';
import '../utils/song_sort.dart';
import 'repository_providers.dart';

// Used by SongsScreen
final songSearchQueryProvider = StateProvider<String>((ref) => '');

// FIX: Used by SearchScreen to prevent state collision
final globalSearchQueryProvider = StateProvider<String>((ref) => '');

final songSortOptionProvider =
    StateProvider<SongSortOption>((ref) => SongSortOption.title);

final _getAllSongsUseCaseProvider = Provider<GetAllSongsUseCase>((ref) {
  return GetAllSongsUseCase(ref.watch(songRepositoryProvider));
});

final _searchSongsUseCaseProvider = Provider<SearchSongsUseCase>((ref) {
  return SearchSongsUseCase(ref.watch(songRepositoryProvider));
});

final _indexDirectoriesUseCaseProvider =
    Provider<IndexDirectoriesUseCase>((ref) {
  return IndexDirectoriesUseCase(ref.watch(songRepositoryProvider));
});

final _refreshLibraryUseCaseProvider = Provider<RefreshLibraryUseCase>((ref) {
  return RefreshLibraryUseCase(ref.watch(songRepositoryProvider));
});

final sortedSongsProvider = FutureProvider<List<Song>>((ref) async {
  final query = ref.watch(songSearchQueryProvider);
  final sortOption = ref.watch(songSortOptionProvider);

  final result = query.isEmpty
      ? await ref.watch(_getAllSongsUseCaseProvider).call(const NoParams())
      : await ref.watch(_searchSongsUseCaseProvider).call(query);

  return result.when(
    ok: (songs) {
      final sorted = List<Song>.of(songs)
        ..sort((a, b) => compareSongs(a, b, sortOption));
      return sorted;
    },
    err: (failure) => throw failure,
  );
});

// FIX: Provider specifically for the global SearchScreen
final globalSearchResultsProvider = FutureProvider<List<Song>>((ref) async {
  final query = ref.watch(globalSearchQueryProvider);
  if (query.isEmpty) return [];
  
  final result = await ref.watch(_searchSongsUseCaseProvider).call(query);
  return result.when(
    ok: (songs) => songs,
    err: (failure) => throw failure,
  );
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