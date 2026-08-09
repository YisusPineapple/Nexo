import '../../core/error/failures.dart';
import '../../core/utils/result.dart';
import '../entities/item_interaction.dart';
import '../entities/song.dart';
import '../value_objects/song_id.dart';

abstract interface class UserMetricsRepository {
  Future<Result<void, Failure>> logSongPlay(SongId songId);
  
  Future<Result<void, Failure>> setInteraction({
    required String itemId,
    required ItemType itemType,
    required InteractionType? interaction, // null removes the interaction
  });
  
  Future<Result<InteractionType?, Failure>> getInteraction({
    required String itemId,
    required ItemType itemType,
  });

  // --- NEW: For You / Metrics queries ---

  /// Returns the most recently played unique songs, ordered by last played time.
  Future<Result<List<Song>, Failure>> getRecentlyPlayed({int limit = 50});

  /// Returns the most frequently played songs, ordered by play count.
  Future<Result<List<Song>, Failure>> getTopTracks({int limit = 20});

  /// Generates a "Daily Mix": combines liked songs and top tracks, shuffles them,
  /// and returns up to [maxTotal] songs. If no liked/top history exists, falls
  /// back to random songs from the library.
  Future<Result<List<Song>, Failure>> getDailyMix({
    int likedLimit = 20,
    int topLimit = 30,
    int maxTotal = 50,
  });
}