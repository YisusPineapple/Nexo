import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../domain/entities/queue_source.dart';
import '../../../domain/value_objects/album_id.dart';
import '../../../domain/value_objects/artist_id.dart';

/// Serializes the sealed [QueueSource] hierarchy to a single JSON TEXT
/// column instead of six mostly-null sparse columns (one set per
/// subtype). [QueueSource] is small, closed, and purely informational
/// (per its own class docs, it never affects playback behavior), so a
/// single narrow column is a better fit here than widening this table
/// for variants that are mutually exclusive by construction.
///
/// [toSql] switches exhaustively over every [QueueSource] subtype —
/// Dart's sealed-class exhaustiveness check means adding a new
/// subtype to queue_source.dart without updating this file is a
/// compile error here, not a silent runtime gap.
class QueueSourceConverter extends TypeConverter<QueueSource, String> {
  const QueueSourceConverter();

  @override
  QueueSource fromSql(String fromDb) {
    final map = jsonDecode(fromDb) as Map<String, Object?>;
    return switch (map['type']) {
      'manual' => const ManualQueueSource(),
      'artist' => ArtistQueueSource(
          artistId: ArtistId(map['artistId']! as String),
          artistName: map['artistName']! as String,
        ),
      'album' => AlbumQueueSource(
          albumId: AlbumId(map['albumId']! as String),
          albumName: map['albumName']! as String,
        ),
      'playlist' => PlaylistQueueSource(
          playlistId: map['playlistId']! as String,
          playlistName: map['playlistName']! as String,
        ),
      'genre' => GenreQueueSource(genreName: map['genreName']! as String),
      'folder' => FolderQueueSource(
          folderPath: map['folderPath']! as String,
          folderName: map['folderName']! as String,
        ),
      final other => throw FormatException(
          'Unknown QueueSource type "$other" found in stored data.',
        ),
    };
  }

  @override
  String toSql(QueueSource value) {
    final map = switch (value) {
      ManualQueueSource() => {'type': 'manual'},
      ArtistQueueSource(:final artistId, :final artistName) => {
          'type': 'artist',
          'artistId': artistId.value,
          'artistName': artistName,
        },
      AlbumQueueSource(:final albumId, :final albumName) => {
          'type': 'album',
          'albumId': albumId.value,
          'albumName': albumName,
        },
      PlaylistQueueSource(:final playlistId, :final playlistName) => {
          'type': 'playlist',
          'playlistId': playlistId,
          'playlistName': playlistName,
        },
      GenreQueueSource(:final genreName) => {
          'type': 'genre',
          'genreName': genreName,
        },
      FolderQueueSource(:final folderPath, :final folderName) => {
          'type': 'folder',
          'folderPath': folderPath,
          'folderName': folderName,
        },
    };
    return jsonEncode(map);
  }
}
