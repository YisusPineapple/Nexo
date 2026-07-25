// Closed set of decodable audio container/codec formats (FORMATOS
// SOPORTADOS in the spec). Kept as an enum rather than a free-form
// String so an unsupported format is a compile-time impossibility
// once a Song exists — the data layer maps raw file
// extensions/mime-types to this enum at ingestion; anything it can't
// map becomes a decode failure at that boundary, never reaching
// playback as an unknown string.
enum AudioFormat {
  mp3,
  aac,
  flac,
  opus,
  vorbis,
  wav,
  wma,
  aiff,
  eac3,
  ac4,
  webm,
}