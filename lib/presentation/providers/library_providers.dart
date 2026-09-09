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

// --- Virtual Pagination Providers ---

final alphabeticalIndexProvider =
    FutureProvider<List<(String, int)>>((ref) async {
  final sortConfig = ref.watch(songSortProvider);

  ref.listen(
    StreamProvider(
        (ref) => ref.watch(songRepositoryProvider).coversUpdatedStream),
    (_, __) => ref.invalidateSelf(),
  );

  final result = await ref.watch(songRepositoryProvider).getAlphabeticalIndex(
        sortOption: sortConfig.option,
        isAscending: sortConfig.isAscending,
      );

  return result.unwrapOrThrow();
});

class SongsWindowState {
  const SongsWindowState({
    required this.loadedPages,
    required this.totalCount,
  });

  final Map<int, List<Song>> loadedPages;
  final int totalCount;

  SongsWindowState copyWith({
    Map<int, List<Song>>? loadedPages,
    int? totalCount,
  }) {
    return SongsWindowState(
      loadedPages: loadedPages ?? this.loadedPages,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

final songsWindowProvider =
    NotifierProvider<SongsWindowNotifier, SongsWindowState>(
  SongsWindowNotifier.new,
);

class SongsWindowNotifier extends Notifier<SongsWindowState> {
  static const int pageSize = 100;
  static const int _maxCachedPages = 3;

  final List<int> _lruQueue = [];
  // FIX: Added a flag to prevent concurrent count fetches
  bool _isFetchingCount = false;

  @override
  SongsWindowState build() {
    ref.watch(songSortProvider);

    ref.listen(
      StreamProvider(
          (ref) => ref.watch(songRepositoryProvider).coversUpdatedStream),
      (_, __) => _refreshCurrentPages(),
    );

    final indexAsync = ref.watch(alphabeticalIndexProvider);
    if (indexAsync is AsyncData && !_isFetchingCount) {
      final index = indexAsync.value!;
      if (index.isNotEmpty) {
        _isFetchingCount = true;
        // Fire and forget the count fetch
        Future.microtask(_fetchTotalCount);
      }
    }

    return const SongsWindowState(loadedPages: {}, totalCount: 0);
  }

  Future<void> _fetchTotalCount() async {
    try {
      final result = await ref.read(_getAllSongsUseCaseProvider).call((
        sortOption: SongSortOption.title,
        isAscending: true,
      ));

      if (result.isOk) {
        state = state.copyWith(totalCount: result.valueOrNull!.length);
      }
    } finally {
      _isFetchingCount = false;
    }
  }

  Future<void> _refreshCurrentPages() async {
    final currentPages = state.loadedPages.keys.toList();
    for (final page in currentPages) {
      await _loadPage(page, forceRefresh: true);
    }
  }

  Future<void> ensureLoaded(int itemIndex) async {
    final page = itemIndex ~/ pageSize;
    if (state.loadedPages.containsKey(page)) {
      _lruQueue.remove(page);
      _lruQueue.add(page);
      return;
    }

    await _loadPage(page);
  }

  Future<void> _loadPage(int page, {bool forceRefresh = false}) async {
    if (!forceRefresh && state.loadedPages.containsKey(page)) return;

    final sortConfig = ref.read(songSortProvider);
    final result = await ref.read(songRepositoryProvider).getSongsWindow(
          offset: page * pageSize,
          limit: pageSize,
          sortOption: sortConfig.option,
          isAscending: sortConfig.isAscending,
        );

    if (result.isOk) {
      final newPages = Map<int, List<Song>>.from(state.loadedPages);
      newPages[page] = result.valueOrNull!;

      if (!forceRefresh) {
        _lruQueue.add(page);
        if (_lruQueue.length > _maxCachedPages) {
          final oldestPage = _lruQueue.removeAt(0);
          newPages.remove(oldestPage);
        }
      }

      state = state.copyWith(loadedPages: newPages);
    }
  }

  Song? getSongAtIndex(int index) {
    final page = index ~/ pageSize;
    final indexInPage = index % pageSize;

    final pageData = state.loadedPages[page];
    if (pageData == null || indexInPage >= pageData.length) {
      return null;
    }
    return pageData[indexInPage];
  }
}

// --------------------------------------------------

final sortedSongsProvider = FutureProvider<List<Song>>((ref) async {
  final query = ref.watch(songSearchQueryProvider);
  final sortConfig = ref.watch(songSortProvider);

  ref.listen(
    StreamProvider(
        (ref) => ref.watch(songRepositoryProvider).coversUpdatedStream),
    (_, __) => ref.invalidateSelf(),
  );

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
        // FIX: Only update state if the total is known or it's the first discovery event
        if (total > 0 || current % 50 == 0) {
          state = AsyncData((current: current, total: total));
        }
      },
    );

    state = result.when(
      ok: (_) {
        ref.invalidate(sortedSongsProvider);
        ref.invalidate(alphabeticalIndexProvider);
        ref.invalidate(songsWindowProvider);
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
        if (total > 0 || current % 50 == 0) {
          state = AsyncData((current: current, total: total));
        }
      },
    );

    state = result.when(
      ok: (_) {
        ref.invalidate(sortedSongsProvider);
        ref.invalidate(alphabeticalIndexProvider);
        ref.invalidate(songsWindowProvider);
        return const AsyncData(null);
      },
      err: (failure) => AsyncValue<IndexingProgress?>.error(
        failure,
        StackTrace.current,
      ),
    );
  }
}
