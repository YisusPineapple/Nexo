import 'package:test/test.dart';
import 'package:nexo/domain/entities/audio_format.dart';
import 'package:nexo/domain/entities/song.dart';
import 'package:nexo/domain/value_objects/artist_id.dart';
import 'package:nexo/domain/value_objects/song_id.dart';

Song _buildSong({
  String id = 's1',
  String title = 'Track One',
  Duration duration = const Duration(minutes: 3),
  int fileSizeBytes = 5000000,
  String filePath = '/music/track.mp3',
}) {
  return Song.create(
    id: SongId(id),
    title: title,
    trackArtistId: const ArtistId('artist-1'),
    duration: duration,
    filePath: filePath,
    format: AudioFormat.mp3,
    fileSizeBytes: fileSizeBytes,
    dateAddedUtc: DateTime.utc(2026, 1, 1),
  ).valueOrNull!;
}

void main() {
  group('Song.create', () {
    test('succeeds with valid required fields', () {
      final result = Song.create(
        id: const SongId('s1'),
        title: 'Track One',
        trackArtistId: const ArtistId('artist-1'),
        duration: const Duration(minutes: 3),
        filePath: '/music/track.mp3',
        format: AudioFormat.flac,
        fileSizeBytes: 30000000,
        dateAddedUtc: DateTime.utc(2026, 1, 1),
      );
      expect(result.isOk, isTrue);
      expect(result.valueOrNull?.format, AudioFormat.flac);
      expect(result.valueOrNull?.genreNames, isEmpty);
    });

    test('rejects a negative duration', () {
      final result = _buildSong;
      expect(
        Song.create(
          id: const SongId('s1'),
          title: 'Track One',
          trackArtistId: const ArtistId('artist-1'),
          duration: const Duration(seconds: -1),
          filePath: '/music/track.mp3',
          format: AudioFormat.mp3,
          fileSizeBytes: 1000,
          dateAddedUtc: DateTime.utc(2026, 1, 1),
        ).isErr,
        isTrue,
      );
      // ignore unused warning for clarity of helper reuse elsewhere
      expect(result, isA<Function>());
    });

    test('rejects a negative fileSizeBytes', () {
      expect(
        Song.create(
          id: const SongId('s1'),
          title: 'Track One',
          trackArtistId: const ArtistId('artist-1'),
          duration: const Duration(minutes: 1),
          filePath: '/music/track.mp3',
          format: AudioFormat.mp3,
          fileSizeBytes: -1,
          dateAddedUtc: DateTime.utc(2026, 1, 1),
        ).isErr,
        isTrue,
      );
    });

    test('rejects an empty filePath', () {
      expect(
        Song.create(
          id: const SongId('s1'),
          title: 'Track One',
          trackArtistId: const ArtistId('artist-1'),
          duration: const Duration(minutes: 1),
          filePath: '',
          format: AudioFormat.mp3,
          fileSizeBytes: 1000,
          dateAddedUtc: DateTime.utc(2026, 1, 1),
        ).isErr,
        isTrue,
      );
    });
  });

  group('Song equality', () {
    test('two Song instances with the same id are equal regardless of '
        'other fields', () {
      final a = _buildSong(id: 's1', title: 'Original Title');
      final b = _buildSong(id: 's1', title: 'Retagged Title');
      expect(a, equals(b));
    });

    test('two Song instances with different ids are not equal', () {
      final a = _buildSong(id: 's1');
      final b = _buildSong(id: 's2');
      expect(a == b, isFalse);
    });
  });

  group('Song.copyWith', () {
    test('updates isMissing and coverArtPath, preserves the rest', () {
      final original = _buildSong();
      final updated = original.copyWith(
        isMissing: true,
        coverArtPath: '/cache/covers/s1.jpg',
      );

      expect(updated.isMissing, isTrue);
      expect(updated.coverArtPath, '/cache/covers/s1.jpg');
      expect(updated.title, original.title);
      expect(updated.duration, original.duration);
    });
  });
}