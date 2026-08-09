import 'package:drift/drift.dart';

/// Universal table to store user preferences (Likes / Dislikes) for ANY
/// entity type (Songs, Albums, Artists, Playlists).
/// 
/// We use a dedicated table instead of adding an 'isLiked' column to Songs
/// because Artists and Albums don't have their own tables in this app
/// (they are derived dynamically). This allows us to "like" an Artist by
/// storing their name as the [itemId].
@DataClassName('ItemInteractionRow')
class ItemInteractions extends Table {
  /// The SongId, PlaylistId, Album name, or Artist name.
  TextColumn get itemId => text()();
  
  /// 'song', 'album', 'artist', or 'playlist'.
  TextColumn get itemType => text()();
  
  /// 1 for Like (Heart), -1 for Dislike (Heart-break).
  /// If a user removes their like, the row is deleted entirely.
  IntColumn get interaction => integer()();
  
  IntColumn get timestampUtcMs => integer()();

  @override
  Set<Column> get primaryKey => {itemId, itemType};
}