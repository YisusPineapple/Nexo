import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../../core/utils/result_extensions.dart';
import '../../domain/entities/song.dart';
import '../../domain/entities/song_sort_option.dart';
import 'library_providers.dart';
import 'repository_providers.dart';

/// Page size for reactive windowed loading. Fixed at 50 per
/// Sprint9_P0_T2.md §2.4.
const int kSongsWindowPageSize = 50;

/// How many pages may live in memory at once. 4 × 50 = ~200 songs, the
/// worst-case RAM ceiling named in the same section.
const int kSongsWindowMaxCachedPages = 4;

/// Sentinel for [SongsWindowState.copyWith]'s nullable `initialError`,
/// so `copyWith(initialError: null)` clears the error while
/// `copyWith()` (no argument) preserves it.
const Object _unset = Object();

/// UI-facing state of the paginated songs list. Loaded pages live in
/// [pages]; a `null` value from [songAt] means "not yet loaded, show a
/// placeholder" — never an error.
class SongsWindowState {
  const SongsWindowState({
    required this.totalCount,
    required this.pages,
    required this.loadingPages,
    required this.sortConfig,
    required this.query,
    required this.isInitialLoading,
    this.initialError,
  });

  /// Best-known total row count for the current sort+query. Drives
  /// `ListView.builder`'s `itemCount`.
  final int totalCount;

  /// Loaded pages keyed by page index (0-based). A missing key means
  /// "not loaded"; an empty list is a legitimate value (empty page).
  final Map<int, List<Song>> pages;

  /// Page indices whose initial query is in flight. Used to avoid
  /// double-subscribing when `itemBuilder` fires repeatedly for the same
  /// placeholder row during fast scroll.
  final Set<int> loadingPages;

  /// Sort descriptor the current state was built for. Changing it via
  /// [songSortProvider] invalidates the Notifier and triggers a full
  /// reload.
  final SortConfig<SongSortOption> sortConfig;

  /// FTS5 query the current state was built for. Empty means
  /// "unfiltered catalog". Changing it via [songSearchQueryProvider]
  /// invalidates the Notifier and triggers a full reload.
  final String query;

  /// True until the first `watchSongsCount` emission arrives. Only this
  /// first-load case shows a full-screen spinner; incremental page
  /// loads never toggle it.
  final bool isInitialLoading;

  /// Non-null if `watchSongsCount` failed before emitting a value.
  /// Retained so the screen can offer a retry affordance without
  /// crashing.
  final Failure? initialError;

  /// Returns the song at [index] if its page is loaded, `null`
  /// otherwise. O(1): arithmetic + list access.
  Song? songAt(int index) {
    if (index < 0 || index >= totalCount) return null;
    final page = pages[index ~/ kSongsWindowPageSize];
    if (page == null) return null;
    final offsetInPage = index % kSongsWindowPageSize;
    if (offsetInPage >= page.length) return null;
    return page[offsetInPage];
  }

  SongsWindowState copyWith({
    int? totalCount,
    Map<int, List<Song>>? pages,
    Set<int>? loadingPages,
    SortConfig<SongSortOption>? sortConfig,
    String? query,
    bool? isInitialLoading,
    Object? initialError = _unset,
  }) {
    return SongsWindowState(
      totalCount: totalCount ?? this.totalCount,
      pages: pages ?? this.pages,
      loadingPages: loadingPages ?? this.loadingPages,
      sortConfig: sortConfig ?? this.sortConfig,
      query: query ?? this.query,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      initialError: identical(initialError, _unset)
          ? this.initialError
          : initialError as Failure?,
    );
  }

  @override
  String toString() {
    return 'SongsWindowState(totalCount: $totalCount, '
        'loadedPages: ${pages.keys.toList()..sort()}, '
        'loadingPages: $loadingPages, '
        'sort: ${sortConfig.option.name}, '
        'asc: ${sortConfig.isAscending}, '
        'query: "$query", '
        'isInitialLoading: $isInitialLoading, '
        'hasError: ${initialError != null})';
  }
}

/// Reactive paginated window over the songs catalog. Backed by
/// `SongRepository.watchSongsWindow` (Drift `.watch()`), with an LRU
/// cache of loaded pages.
///
/// Deliberately a plain [Notifier], not an [AsyncNotifier]: incremental
/// page loads must NOT reset the state to AsyncLoading, or the whole
/// list would flash every time a new page enters the viewport.
/// [SongsWindowState.isInitialLoading] models the single case that
/// actually needs a spinner — the very first count+page-0 load.
///
/// Lifecycle:
///   * `build()` reads [songSortProvider] and [songSearchQueryProvider];
///     changing either invalidates this Notifier and triggers a full
///     reload from page 0.
///   * Page subscriptions are cancelled on dispose, on LRU eviction,
///     and when a page index falls outside a shrunken total count.
///   * `loadPage(n)` is idempotent: a page already loaded or already
///     being loaded is a no-op (it just refreshes LRU recency).
class SongsWindowNotifier extends Notifier<SongsWindowState> {
  StreamSubscription<Result<int, Failure>>? _countSub;
  final Map<int, StreamSubscription<Result<List<Song>, Failure>>> _pageSubs =
      {};

  /// Page indices in least-recently-used-first order. `_lruOrder.last` is
  /// the most recent. Kept in sync with `_pageSubs.keys`.
  final List<int> _lruOrder = [];

  @override
  SongsWindowState build() {
    final sortConfig = ref.watch(songSortProvider);
    final query = ref.watch(songSearchQueryProvider);

    // Defensive: clear anything left by a previous build iteration.
    // Riverpod runs previous onDispose callbacks before re-running build,
    // so this is normally redundant — it stays as a belt-and-suspenders
    // guard for the rebuild-during-in-flight-emission race.
    _cancelAllSubscriptions();

    ref.onDispose(_cancelAllSubscriptions);

    final initial = SongsWindowState(
      totalCount: 0,
      pages: const {},
      loadingPages: const {},
      sortConfig: sortConfig,
      query: query,
      isInitialLoading: true,
    );

    // Deferred: the Notifier cannot observe `this.state` until build() has
    // returned at least once. Scheduling the load as a microtask guarantees
    // that ordering.
    Future.microtask(_init);

    return initial;
  }

  Future<void> _init() async {
    final repo = ref.read(songRepositoryProvider);
    final capturedSort = state.sortConfig;
    final capturedQuery = state.query;

    _countSub = repo.watchSongsCount(query: capturedQuery).listen((result) {
      // Stale emission from a previous build iteration (sort/query changed
      // while this stream was still flushing). Drop silently.
      if (state.sortConfig != capturedSort || state.query != capturedQuery) {
        return;
      }
      result.when(
        ok: (count) {
          state = state.copyWith(
            totalCount: count,
            isInitialLoading: false,
            initialError: null,
          );
          _evictPagesBeyondTotal(count);
        },
        err: (failure) {
          state = state.copyWith(
            isInitialLoading: false,
            initialError: failure,
          );
        },
      );
    });

    loadPage(0);
  }

  /// Loads [pageIndex] if not already loaded or in flight. Idempotent:
  /// repeated calls during fast scroll for the same placeholder row are
  /// collapsed, and an already-loaded page just refreshes its LRU
  /// recency.
  void loadPage(int pageIndex) {
    if (pageIndex < 0) return;

    if (_pageSubs.containsKey(pageIndex)) {
      _touchLru(pageIndex);
      return;
    }

    final repo = ref.read(songRepositoryProvider);
    final offset = pageIndex * kSongsWindowPageSize;

    state = state.copyWith(
      loadingPages: {...state.loadingPages, pageIndex},
    );

    final sub = repo
        .watchSongsWindow(
      offset: offset,
      limit: kSongsWindowPageSize,
      sortOption: state.sortConfig.option,
      isAscending: state.sortConfig.isAscending,
      query: state.query,
    )
        .listen((result) {
      result.when(
        ok: (songs) {
          _onPageLoaded(pageIndex, songs);
        },
        err: (_) {
          // Page-level failure: drop the placeholder from `loadingPages`
          // but leave the page absent from `pages`. The UI keeps showing
          // the placeholder row; no state-wide error surfaces, since a
          // single failed page is not the same as a failed Notifier.
          state = state.copyWith(
            loadingPages: {...state.loadingPages}..remove(pageIndex),
          );
        },
      );
    });

    _pageSubs[pageIndex] = sub;
    _touchLru(pageIndex);
    _evictIfNeeded();
  }

  void _onPageLoaded(int pageIndex, List<Song> songs) {
    final newPages = Map<int, List<Song>>.of(state.pages)..[pageIndex] = songs;
    final newLoading = {...state.loadingPages}..remove(pageIndex);

    state = state.copyWith(pages: newPages, loadingPages: newLoading);
    _touchLru(pageIndex);
  }

  void _touchLru(int pageIndex) {
    _lruOrder.remove(pageIndex);
    _lruOrder.add(pageIndex);
  }

  void _evictIfNeeded() {
    while (_lruOrder.length > kSongsWindowMaxCachedPages) {
      final toEvict = _lruOrder.removeAt(0);
      _pageSubs.remove(toEvict)?.cancel();

      final newPages = Map<int, List<Song>>.of(state.pages)..remove(toEvict);
      state = state.copyWith(pages: newPages);
    }
  }

  /// If the total count shrank below a loaded page's range, drop that
  /// page and its subscription. Covers the case where the user excludes
  /// a folder while the Songs tab is open: the backend count drops, and
  /// stale pages beyond the new total must not remain in RAM.
  void _evictPagesBeyondTotal(int newTotal) {
    final maxPageIndex =
        newTotal == 0 ? -1 : (newTotal - 1) ~/ kSongsWindowPageSize;

    final toEvict = _lruOrder.where((p) => p > maxPageIndex).toList();
    if (toEvict.isEmpty) return;

    for (final p in toEvict) {
      _lruOrder.remove(p);
      _pageSubs.remove(p)?.cancel();
    }

    final newPages = <int, List<Song>>{};
    for (final entry in state.pages.entries) {
      if (entry.key <= maxPageIndex) newPages[entry.key] = entry.value;
    }
    state = state.copyWith(pages: newPages);
  }

  void _cancelAllSubscriptions() {
    _countSub?.cancel();
    _countSub = null;
    for (final sub in _pageSubs.values) {
      sub.cancel();
    }
    _pageSubs.clear();
    _lruOrder.clear();
  }

  /// Explicit retry from the screen after an initial count failure.
  /// Cancels everything and re-runs the same boot sequence.
  void retryInitialLoad() {
    _cancelAllSubscriptions();
    state = state.copyWith(
      totalCount: 0,
      pages: const {},
      loadingPages: const {},
      isInitialLoading: true,
      initialError: null,
    );
    Future.microtask(_init);
  }
}

final songsWindowProvider =
    NotifierProvider<SongsWindowNotifier, SongsWindowState>(
  SongsWindowNotifier.new,
);

/// Reactive alphabetical rail index for the paginated list. Backed by
/// `SongRepository.watchAlphabeticalIndex`, which returns cumulative
/// `(letter, firstGlobalIndex)` pairs computed in SQL over `section_key`.
///
/// The rail consumes this without needing the full song list in memory:
/// `AlphabeticalScrollView` in SQL mode jumps by
/// `firstGlobalIndex ~/ crossAxisCount * itemExtent`, and the target
/// page materializes in the next frame through `itemBuilder`.
final songsAlphabeticalIndexProvider =
    StreamProvider<List<(String, int)>>((ref) {
  final sortConfig = ref.watch(songSortProvider);
  final query = ref.watch(songSearchQueryProvider);

  return ref
      .watch(songRepositoryProvider)
      .watchAlphabeticalIndex(
        sortOption: sortConfig.option,
        isAscending: sortConfig.isAscending,
        query: query,
      )
      .map((result) => result.unwrapOrThrow());
});
