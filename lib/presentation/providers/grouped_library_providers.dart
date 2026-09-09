import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/library_aggregates.dart';
import '../../domain/entities/song.dart';
import '../../domain/usecases/library_group_usecases.dart';
import '../../domain/usecases/use_case.dart';
import '../../domain/value_objects/album_id.dart';
import '../../domain/value_objects/artist_id.dart';
import '../../core/utils/artist_splitter.dart';
import '../../core/utils/result_extensions.dart';
import 'library_providers.dart';
import 'repository_providers.dart';

final albumSortProvider = StateProvider<SortConfig<AlbumSortOption>>(
    (ref) => const SortConfig(AlbumSortOption.name));
final artistSortProvider = StateProvider<SortConfig<ArtistSortOption>>(
    (ref) => const SortConfig(ArtistSortOption.name));

final _watchAllAlbumsUseCaseProvider = Provider<WatchAllAlbumsUseCase>((ref) {
  return WatchAllAlbumsUseCase(ref.watch(songRepositoryProvider));
});

final _watchAllArtistsUseCaseProvider = Provider<WatchAllArtistsUseCase>((ref) {
  return WatchAllArtistsUseCase(ref.watch(songRepositoryProvider));
});

final _watchAllGenresUseCaseProvider = Provider<WatchAllGenresUseCase>((ref) {
  return WatchAllGenresUseCase(ref.watch(songRepositoryProvider));
});

final _watchAllFoldersUseCaseProvider = Provider<WatchAllFoldersUseCase>((ref) {
  return WatchAllFoldersUseCase(ref.watch(songRepositoryProvider));
});

final albumsProvider = StreamProvider<List<Album>>((ref) {
  final sortConfig = ref.watch(albumSortProvider);

  return ref.watch(_watchAllAlbumsUseCaseProvider).call((
    sortOption: sortConfig.option,
    isAscending: sortConfig.isAscending,
  )).map((result) => result.unwrapOrThrow());
});

final artistsProvider = StreamProvider<List<Artist>>((ref) {
  final sortConfig = ref.watch(artistSortProvider);

  return ref.watch(_watchAllArtistsUseCaseProvider).call((
    sortOption: sortConfig.option,
    isAscending: sortConfig.isAscending,
  )).map((result) => result.unwrapOrThrow());
});

final genresProvider = StreamProvider<List<Genre>>((ref) {
  return ref
      .watch(_watchAllGenresUseCaseProvider)
      .call(const NoParams())
      .map((result) => result.unwrapOrThrow());
});

final foldersProvider = StreamProvider<List<FolderSummary>>((ref) {
  return ref
      .watch(_watchAllFoldersUseCaseProvider)
      .call(const NoParams())
      .map((result) => result.unwrapOrThrow());
});

// FIX: Added .autoDispose to all detail providers to prevent RAM leaks
final multiArtistSongsProvider = FutureProvider.autoDispose
    .family<List<Song>, String>((ref, artistName) async {
  final allSongs = await ref.watch(sortedSongsProvider.future);
  final target = normalizeArtist(artistName);
  return allSongs.where((song) {
    final artists = splitArtists(song.trackArtistId.value);
    return artists.any((a) => normalizeArtist(a) == target);
  }).toList();
});

final albumSongsProvider =
    StreamProvider.autoDispose.family<List<Song>, String>((ref, albumId) {
  final repo = ref.watch(songRepositoryProvider);
  return repo
      .watchSongsByAlbum(AlbumId(albumId))
      .map((result) => result.unwrapOrThrow());
});

final artistSongsProvider =
    StreamProvider.autoDispose.family<List<Song>, String>((ref, artistId) {
  final repo = ref.watch(songRepositoryProvider);
  return repo
      .watchSongsByArtist(ArtistId(artistId))
      .map((result) => result.unwrapOrThrow());
});

final folderSongsProvider =
    StreamProvider.autoDispose.family<List<Song>, String>((ref, folderPath) {
  final repo = ref.watch(songRepositoryProvider);
  return repo
      .watchSongsByFolder(folderPath)
      .map((result) => result.unwrapOrThrow());
});

final genreSongsProvider =
    FutureProvider.autoDispose.family<List<Song>, String>((ref, genre) async {
  final allSongs = await ref.watch(sortedSongsProvider.future);
  return allSongs.where((s) => s.genreNames.contains(genre)).toList();
});
