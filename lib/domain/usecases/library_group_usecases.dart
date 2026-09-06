import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/library_aggregates.dart';
import '../repositories/song_repository.dart';
import 'use_case.dart';

typedef GetAllAlbumsParams = ({
  AlbumSortOption sortOption,
  bool isAscending,
});

final class GetAllAlbumsUseCase
    implements UseCase<List<Album>, GetAllAlbumsParams> {
  GetAllAlbumsUseCase(this._repository);
  final SongRepository _repository;

  @override
  Future<Result<List<Album>, Failure>> call(GetAllAlbumsParams params) {
    return _repository.getAllAlbums(
      sortOption: params.sortOption,
      isAscending: params.isAscending,
    );
  }
}

typedef GetAllArtistsParams = ({
  ArtistSortOption sortOption,
  bool isAscending,
});

final class GetAllArtistsUseCase
    implements UseCase<List<Artist>, GetAllArtistsParams> {
  GetAllArtistsUseCase(this._repository);
  final SongRepository _repository;

  @override
  Future<Result<List<Artist>, Failure>> call(GetAllArtistsParams params) {
    return _repository.getAllArtists(
      sortOption: params.sortOption,
      isAscending: params.isAscending,
    );
  }
}

final class GetAllGenresUseCase implements UseCase<List<Genre>, NoParams> {
  GetAllGenresUseCase(this._repository);
  final SongRepository _repository;

  @override
  Future<Result<List<Genre>, Failure>> call(NoParams params) {
    return _repository.getAllGenres();
  }
}

final class GetAllFoldersUseCase
    implements UseCase<List<FolderSummary>, NoParams> {
  GetAllFoldersUseCase(this._repository);
  final SongRepository _repository;

  @override
  Future<Result<List<FolderSummary>, Failure>> call(NoParams params) {
    return _repository.getAllFolders();
  }
}
