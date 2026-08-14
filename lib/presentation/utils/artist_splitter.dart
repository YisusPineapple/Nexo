/// Splits a raw artist string (as stored in ID3/Vorbis tags) into
/// individual artist names, handling common collaboration delimiters.
///
/// Examples:
///   "Daft Punk feat. Pharrell" → ["Daft Punk", "Pharrell"]
///   "Artist A & Artist B"     → ["Artist A", "Artist B"]
///   "AC/DC"                   → ["AC/DC"] (no split — no spaces around "/")
///   "R&B Collective"          → ["R&B Collective"] (no split — no spaces)
///
/// The split is intentionally conservative: delimiters must be
/// surrounded by whitespace (or string boundaries) to avoid breaking
/// artist names that legitimately contain these characters.
library;

/// Regex matching any known delimiter surrounded by whitespace.
/// The \s+ anchors ensure "AC/DC" and "R&B" are never split.
final _splitPattern = RegExp(
  r'\s+(?:feat\.?|ft\.?|with|con|vs\.?|x|&|\+|;|/)\s+',
  caseSensitive: false,
);

/// Splits [rawArtist] into individual artist names.
///
/// Returns at least one element. Empty segments are discarded.
/// If the input is blank, returns an empty list.
List<String> splitArtists(String rawArtist) {
  final trimmed = rawArtist.trim();
  if (trimmed.isEmpty) return const [];

  final parts = trimmed.split(_splitPattern);

  final result = <String>[];
  for (final part in parts) {
    final clean = part.trim();
    if (clean.isNotEmpty) {
      result.add(clean);
    }
  }

  // Fallback: if splitting produced nothing usable, return original.
  return result.isEmpty ? [trimmed] : result;
}

/// Normalizes an artist name for grouping and case-insensitive lookup.
/// Collapses internal whitespace runs into single spaces.
String normalizeArtist(String name) {
  return name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}