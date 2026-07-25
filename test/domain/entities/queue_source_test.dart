import 'package:test/test.dart';
import 'package:nexo/domain/entities/queue_source.dart';
import 'package:nexo/domain/value_objects/album_id.dart';
import 'package:nexo/domain/value_objects/artist_id.dart';

void main() {
  group('QueueSource equality', () {
    test('two ArtistQueueSource with the same fields are equal', () {
      const a = ArtistQueueSource(
        artistId: ArtistId('a1'),
        artistName: 'Boards',
      );
      const b = ArtistQueueSource(
        artistId: ArtistId('a1'),
        artistName: 'Boards',
      );
      expect(a, equals(b));
    });

    test('AlbumQueueSource compares by AlbumId and name', () {
      const a = AlbumQueueSource(
        albumId: AlbumId('al1'),
        albumName: 'Music Has The Right To Children',
      );
      const b = AlbumQueueSource(
        albumId: AlbumId('al1'),
        albumName: 'Music Has The Right To Children',
      );
      const c = AlbumQueueSource(albumId: AlbumId('al2'), albumName: 'Other');

      expect(a, equals(b));
      expect(a == c, isFalse);
    });

    test('FolderQueueSource compares by path and name', () {
      const a = FolderQueueSource(
        folderPath: '/music/jazz',
        folderName: 'jazz',
      );
      const b = FolderQueueSource(
        folderPath: '/music/jazz',
        folderName: 'jazz',
      );
      const c = FolderQueueSource(
        folderPath: '/music/rock',
        folderName: 'rock',
      );

      expect(a, equals(b));
      expect(a == c, isFalse);
    });

    test('ManualQueueSource instances are always equal', () {
      expect(const ManualQueueSource(), equals(const ManualQueueSource()));
    });
  });
}