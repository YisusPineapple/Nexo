// Repeat behavior for a PlaybackQueue. Shuffle is intentionally NOT
// modeled here: shuffle mutates queue *order*, while repeat mode
// governs what happens once playback reaches the end of that order.
// Keeping them separate lets each queue combine "shuffled + repeat
// all" without an ad-hoc combined enum value.

enum RepeatMode {
  /// Stop advancing once the last song in the queue finishes.
  off,

  /// Replay the current song indefinitely.
  one,

  /// Loop back to the first song once the queue finishes.
  all,
}