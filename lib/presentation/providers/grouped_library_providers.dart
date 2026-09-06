import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/library_aggregates.dart';
import '../../domain/entities/song.dart';
import '../../domain/usecases/library_group_usecases.dart';
import '../../domain/usecases/use_case.dart';
import '../../domain/value_objects/album_id.dart';
import '../../domain/value_objects/artist_id.dart';
import '../../core/utils/artist_splitter.dart';
import 'library_providers.dart';
import 'repository_providers.dart';

final albumSortProvider = StateProvider<SortConfig<AlbumSortOption>>(
    (ref) => const SortConfig(AlbumSortOption.name));
final artistSortProvider = StateProvider<SortConfig<ArtistSortOption>>(
    (ref) => const SortConfig(ArtistSortOption.name));

final _getAllAlbumsUseCaseProvider = Provider<GetAllAlbumsUseCase>((ref) {
  return GetAllAlbumsUseCase(ref.watch(songRepositoryProvider));
});

final _getAllArtistsUseCaseProvider = Provider<GetAllArtistsUseCase>((ref) {
  return GetAllArtistsUseCase(ref.watch(songRepositoryProvider));
});

final _getAllGenresUseCaseProvider = Provider<GetAllGenresUseCase>((ref) {
  return GetAllGenresUseCase(ref.watch(songRepositoryProvider));
});

final _getAllFoldersUseCaseProvider = Provider<GetAllFoldersUseCase>((ref) {
  return GetAllFoldersUseCase(ref.watch(songRepositoryProvider));
});

final albumsProvider = FutureProvider<List<Album>>((ref) async {
  final sortConfig = ref.watch(albumSortProvider);

  ref.listen(
    StreamProvider(
        (ref) => ref.watch(songRepositoryProvider).coversUpdatedStream),
    (_, __) => ref.invalidateSelf(),
  );

  final result = await ref.watch(_getAllAlbumsUseCaseProvider).call((
    sortOption: sortConfig.option,
    isAscending: sortConfig.isAscending,
  ));

  return result.when(
    ok: (albums) => albums,
    err: (failure) => throw failure,
  );
});

final artistsProvider = FutureProvider<List<Artist>>((ref) async {
  final sortConfig = ref.watch(artistSortProvider);

  ref.listen(
    StreamProvider(
        (ref) => ref.watch(songRepositoryProvider).coversUpdatedStream),
    (_, __) => ref.invalidateSelf(),
  );

  final result = await ref.watch(_getAllArtistsUseCaseProvider).call((
    sortOption: sortConfig.option,
    isAscending: sortConfig.isAscending,
  ));

  return result.when(
    ok: (artists) => artists,
    err: (failure) => throw failure,
  );
});

final genresProvider = FutureProvider<List<Genre>>((ref) async {
  final result =
      await ref.watch(_getAllGenresUseCaseProvider).call(const NoParams());
  return result.when(
    ok: (genres) => genres,
    err: (failure) => throw failure,
  );
});

final foldersProvider = FutureProvider<List<FolderSummary>>((ref) async {
  final result =
      await ref.watch(_getAllFoldersUseCaseProvider).call(const NoParams());
  return result.when(
    ok: (folders) => folders,
    err: (failure) => throw failure,
  );
});

final multiArtistSongsProvider =
    FutureProvider.family<List<Song>, String>((ref, artistName) async {
  final allSongs = await ref.watch(sortedSongsProvider.future);
  final target = normalizeArtist(artistName);
  return allSongs.where((song) {
    final artists = splitArtists(song.trackArtistId.value);
    return artists.any((a) => normalizeArtist(a) == target);
  }).toList();
});

final albumSongsProvider =
    FutureProvider.family<List<Song>, String>((ref, albumId) async {
  final repo = ref.watch(songRepositoryProvider);
  final result = await repo.getSongsByAlbum(AlbumId(albumId));
  return result.when(ok: (songs) => songs, err: (e) => throw e);
});

final artistSongsProvider =
    FutureProvider.family<List<Song>, String>((ref, artistId) async {
  final repo = ref.watch(songRepositoryProvider);
  final result = await repo.getSongsByArtist(ArtistId(artistId));
  return result.when(ok: (songs) => songs, err: (e) => throw e);
});

final folderSongsProvider =
    FutureProvider.family<List<Song>, String>((ref, folderPath) async {
  final repo = ref.watch(songRepositoryProvider);
  final result = await repo.getSongsByFolder(folderPath);
  return result.when(ok: (songs) => songs, err: (e) => throw e);
});

final genreSongsProvider =
    FutureProvider.family<List<Song>, String>((ref, genre) async {
  final allSongs = await ref.watch(sortedSongsProvider.future);
  return allSongs.where((s) => s.genreNames.contains(genre)).toList();
});
