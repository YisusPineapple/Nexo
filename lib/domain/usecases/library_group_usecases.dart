import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/library_aggregates.dart';
import '../repositories/song_repository.dart';
import 'use_case.dart';

typedef GetAllAlbumsParams = ({
  AlbumSortOption sortOption,
  bool isAscending,
});

final class WatchAllAlbumsUseCase
    implements StreamUseCase<List<Album>, GetAllAlbumsParams> {
  WatchAllAlbumsUseCase(this._repository);
  final SongRepository _repository;

  @override
  Stream<Result<List<Album>, Failure>> call(GetAllAlbumsParams params) {
    return _repository.watchAllAlbums(
      sortOption: params.sortOption,
      isAscending: params.isAscending,
    );
  }
}

typedef GetAllArtistsParams = ({
  ArtistSortOption sortOption,
  bool isAscending,
});

final class WatchAllArtistsUseCase
    implements StreamUseCase<List<Artist>, GetAllArtistsParams> {
  WatchAllArtistsUseCase(this._repository);
  final SongRepository _repository;

  @override
  Stream<Result<List<Artist>, Failure>> call(GetAllArtistsParams params) {
    return _repository.watchAllArtists(
      sortOption: params.sortOption,
      isAscending: params.isAscending,
    );
  }
}

final class WatchAllGenresUseCase
    implements StreamUseCase<List<Genre>, NoParams> {
  WatchAllGenresUseCase(this._repository);
  final SongRepository _repository;

  @override
  Stream<Result<List<Genre>, Failure>> call(NoParams params) {
    return _repository.watchAllGenres();
  }
}

final class WatchAllFoldersUseCase
    implements StreamUseCase<List<FolderSummary>, NoParams> {
  WatchAllFoldersUseCase(this._repository);
  final SongRepository _repository;

  @override
  Stream<Result<List<FolderSummary>, Failure>> call(NoParams params) {
    return _repository.watchAllFolders();
  }
}
