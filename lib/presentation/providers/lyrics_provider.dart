import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/lyric_line.dart';
import '../../domain/entities/lyric_segment.dart';
import '../../domain/usecases/get_lyrics_usecase.dart';
import '../providers/playback_providers.dart';
import '../providers/repository_providers.dart';

final lyricsProvider = FutureProvider<List<LyricLine>>((ref) async {
  final queue = ref.watch(playbackControllerProvider).valueOrNull;
  final currentSong = queue?.currentSong;
  if (currentSong == null) return const [];

  final useCase = GetLyricsUseCase(ref.read(lyricsRepositoryProvider));
  final result = await useCase.call(currentSong.id);
  return result.when(
    ok: (lines) => lines,
    err: (_) => const [],
  );
});

// FIX: Changed from StateProvider to Notifier to sync with the Database
final lyricOffsetProvider = NotifierProvider<LyricOffsetNotifier, int>(LyricOffsetNotifier.new);

class LyricOffsetNotifier extends Notifier<int> {
  @override
  int build() {
    final queue = ref.watch(playbackControllerProvider).valueOrNull;
    return queue?.currentSong?.lyricOffsetMs ?? 0;
  }

  void updateOffset(int newOffset) {
    state = newOffset;
    final queue = ref.read(playbackControllerProvider).valueOrNull;
    final currentSong = queue?.currentSong;
    if (currentSong != null) {
      // Fire and forget the DB update
      ref.read(songRepositoryProvider).updateLyricOffset(currentSong.id, newOffset);
    }
  }
}

final currentLyricIndexProvider = Provider<int>((ref) {
  final lines = ref.watch(lyricsProvider).valueOrNull;
  if (lines == null || lines.isEmpty) return -1;

  final position = ref.watch(positionStreamProvider).valueOrNull;
  if (position == null) return -1;

  final offsetMs = ref.watch(lyricOffsetProvider);
  final effectivePosition = position + Duration(milliseconds: offsetMs);

  int index = -1;
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].lineTimestamp <= effectivePosition) {
      index = i;
    } else {
      break;
    }
  }
  return index;
});

final currentLyricSegmentProvider = Provider<LyricSegment?>((ref) {
  final lines = ref.watch(lyricsProvider).valueOrNull;
  if (lines == null || lines.isEmpty) return null;

  final currentLineIndex = ref.watch(currentLyricIndexProvider);
  if (currentLineIndex < 0 || currentLineIndex >= lines.length) return null;

  final position = ref.watch(positionStreamProvider).valueOrNull;
  if (position == null) return null;

  final offsetMs = ref.watch(lyricOffsetProvider);
  final effectivePosition = position + Duration(milliseconds: offsetMs);

  final activeLine = lines[currentLineIndex];
  if (activeLine.segments.isEmpty) return null;

  LyricSegment? activeSegment;
  for (final segment in activeLine.segments) {
    if (segment.timestamp <= effectivePosition) {
      activeSegment = segment;
    } else {
      break;
    }
  }

  return activeSegment ?? activeLine.segments.first;
});