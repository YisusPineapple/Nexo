import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/lyric_line.dart';
import '../../domain/entities/lyric_segment.dart';
import '../../domain/usecases/get_lyrics_usecase.dart';
import '../providers/playback_providers.dart';
import '../providers/repository_providers.dart';

/// Loads the lyrics for the currently playing song.
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

/// Returns the index of the lyric line that should be highlighted
/// based on the current playback position.
final currentLyricIndexProvider = Provider<int>((ref) {
  final lines = ref.watch(lyricsProvider).valueOrNull;
  if (lines == null || lines.isEmpty) return -1;

  final position = ref.watch(positionStreamProvider).valueOrNull;
  if (position == null) return -1;

  // Find the last line whose timestamp is <= current position.
  int index = -1;
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].lineTimestamp <= position) {
      index = i;
    } else {
      break;
    }
  }
  return index;
});

/// Returns the active segment within the currently active lyric line.
final currentLyricSegmentProvider = Provider<LyricSegment?>((ref) {
  final lines = ref.watch(lyricsProvider).valueOrNull;
  if (lines == null || lines.isEmpty) return null;

  final currentLineIndex = ref.watch(currentLyricIndexProvider);
  if (currentLineIndex < 0 || currentLineIndex >= lines.length) return null;

  final position = ref.watch(positionStreamProvider).valueOrNull;
  if (position == null) return null;

  final activeLine = lines[currentLineIndex];
  if (activeLine.segments.isEmpty) return null;

  LyricSegment? activeSegment;
  for (final segment in activeLine.segments) {
    if (segment.timestamp <= position) {
      activeSegment = segment;
    } else {
      break;
    }
  }

  return activeSegment ?? activeLine.segments.first;
});
