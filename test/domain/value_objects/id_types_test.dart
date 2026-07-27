import 'package:test/test.dart';
import 'package:nexo/domain/value_objects/album_id.dart';
import 'package:nexo/domain/value_objects/artist_id.dart';
import 'package:nexo/domain/value_objects/queue_id.dart';
import 'package:nexo/domain/value_objects/song_id.dart';

void main() {
  test('same-valued ids of the same type are equal', () {
    expect(const SongId('s1'), equals(const SongId('s1')));
    expect(const ArtistId('a1'), equals(const ArtistId('a1')));
    expect(const AlbumId('al1'), equals(const AlbumId('al1')));
    expect(const QueueId('q1'), equals(const QueueId('q1')));
  });

  test('different-valued ids of the same type are not equal', () {
    expect(const SongId('s1') == const SongId('s2'), isFalse);
  });

  test('.value exposes the underlying String', () {
    const id = SongId('s1');
    expect(id.value, 's1');
  });
}
