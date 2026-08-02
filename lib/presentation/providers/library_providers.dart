import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/song.dart';
import '../../domain/usecases/get_all_songs_usecase.dart';
import '../../domain/usecases/search_songs_usecase.dart';
import '../../domain/usecases/use_case.dart';
import '../utils/song_sort.dart';
import 'repository_providers.dart';

/// Committed search text — set by SongsScreen only AFTER its own
/// 300ms debounce fires. Empty means "no search, show everything".
final songSearchQueryProvider = StateProvider<String>((ref) => '');

final songSortOptionProvider =
    StateProvider<SongSortOption>((ref) => SongSortOption.title);

final _getAllSongsUseCaseProvider = Provider<GetAllSongsUseCase>((ref) {
  return GetAllSongsUseCase(ref.watch(songRepositoryProvider));
});

final _searchSongsUseCaseProvider = Provider<SearchSongsUseCase>((ref) {
  return SearchSongsUseCase(ref.watch(songRepositoryProvider));
});

/// Resolves search vs. full-library fetch, then applies the current
/// sort — exactly the "Presentation/use-case concern layered on top
/// of one query" the Domain repository's own docs describe.
///
/// Throwing the [Failure] rather than returning it is a deliberate,
/// one-time translation AT this boundary: FutureProvider already
/// catches exceptions into AsyncValue.error, Flutter's own idiom for
/// surfacing async failures via .when(). Nowhere else in the app does
/// a Result get thrown instead of handled.
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