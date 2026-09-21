#!/usr/bin/env bash
# Regenerates the synthetic T9 fixtures in test/fixtures/t9_amr/.
#
# Run from the repo root:
#   bash tool/generate_t9_fixtures.sh
#
# These are NOT the original spike fixtures (those were commercial
# audio, unsuitable for committing). They are short synthetic tones with
# controlled tags, byte-identical across runs because ffmpeg is
# deterministic given the same input and options.
#
# The one thing ffmpeg cannot synthesize is ReplayGain — FLAC gets its
# tags via metaflac, Opus via ffmpeg's own metadata writer. Every other
# format is deliberately left ReplayGain-free: that is exactly the
# condition T9 measured (desktop formats report none, Android formats
# do), and it must not accidentally drift.
#
# NOTE: vorbiscomment (from vorbis-tools) does NOT operate on FLAC —
# it only understands raw Ogg Vorbis. Use metaflac for FLAC.
set -euo pipefail

FIX=test/fixtures/t9_amr
mkdir -p "$FIX"

TONE="sine=frequency=440:duration=2"
COMMON_META=(
  -metadata title="T9 Fixture"
  -metadata artist="T9 Fixture Artist"
  -metadata album="T9 Fixture Album"
  -metadata track="1"
  -metadata date="2026"
  -metadata genre="Test"
)

# --- 01 FLAC with ReplayGain (VorbisMetadata path) ---
ffmpeg -y -f lavfi -i "$TONE" "${COMMON_META[@]}" \
  -c:a flac -q:a 5 "$FIX/01_flac_replaygain.flac"
metaflac \
  --set-tag="REPLAYGAIN_TRACK_GAIN=-3.50 dB" \
  --set-tag="REPLAYGAIN_TRACK_PEAK=0.98765" \
  --set-tag="REPLAYGAIN_ALBUM_GAIN=-2.10 dB" \
  --set-tag="REPLAYGAIN_ALBUM_PEAK=0.98765" \
  "$FIX/01_flac_replaygain.flac"

# --- 02 MP3 with no ReplayGain (Mp3Metadata path, P1 desktop) ---
ffmpeg -y -f lavfi -i "$TONE" "${COMMON_META[@]}" \
  -c:a libmp3lame -q:a 9 "$FIX/02_mp3_no_rg.mp3"

# --- 03 MP3 with ID3v2 ReplayGain TXXX frames. The reader is expected
# --- to STILL surface null ReplayGain — this is the strongest form of
# --- the P1 assertion: not just "tags absent", but "tags present and
# --- deliberately not read".
if command -v id3v2 >/dev/null 2>&1; then
  cp "$FIX/02_mp3_no_rg.mp3" "$FIX/03_mp3_with_rg_tags.mp3"
  id3v2 \
    --TXXX "REPLAYGAIN_TRACK_GAIN:-3.50 dB" \
    --TXXX "REPLAYGAIN_TRACK_PEAK:0.98765" \
    "$FIX/03_mp3_with_rg_tags.mp3"
else
  # No id3v2 available: fall back to a plain copy so downstream tests
  # at least have the file, with a warning.
  cp "$FIX/02_mp3_no_rg.mp3" "$FIX/03_mp3_with_rg_tags.mp3"
  echo "WARN: id3v2 not found; 03 has no ReplayGain tags." >&2
fi

# --- 04 M4A / AAC ---
ffmpeg -y -f lavfi -i "$TONE" "${COMMON_META[@]}" \
  -c:a aac -b:a 96k "$FIX/04_sample.m4a"

# --- 05 Opus with ReplayGain (VorbisMetadata path). ffmpeg writes
# --- arbitrary keys as Vorbis comments on OggOpus, so no post-step.
ffmpeg -y -f lavfi -i "$TONE" "${COMMON_META[@]}" \
  -metadata "REPLAYGAIN_TRACK_GAIN=-3.50 dB" \
  -metadata "REPLAYGAIN_TRACK_PEAK=0.98765" \
  -metadata "REPLAYGAIN_ALBUM_GAIN=-2.10 dB" \
  -metadata "REPLAYGAIN_ALBUM_PEAK=0.98765" \
  -c:a libopus -b:a 96k "$FIX/05_sample.opus"

# --- 06 WAV ---
ffmpeg -y -f lavfi -i "$TONE" "${COMMON_META[@]}" \
  -c:a pcm_s16le "$FIX/06_sample.wav"

# --- 07 Corrupt MP3: genuinely invalid data — 1024 bytes of 0xAA,
# --- which is neither a valid MP3 sync word (0xFFFB/0xFFF3) nor an
# --- ID3v2 header ("ID3"). The datasource's try-catch must collapse
# --- this to ExtractedMetadata.empty(), and _buildSong must then
# --- assign the fallback artist that the T9 recovery pass later
# --- rewrites. This is the file that proves "corrupt audio does not
# --- crash the scanner".
# ---
# --- Note: `head -c 5000` of a valid MP3 does NOT produce this — the
# --- ID3v2 tag block lives at the START of the file, so truncating
# --- the audio body still leaves readable tags. Verified the hard way:
# --- the first run of metadata_datasource_test failed because the
# --- truncated file reported a perfectly valid title.
printf '\xAA%.0s' {1..1024} > "$FIX/07_corrupt.mp3"

# --- 08 OGG Vorbis ---
ffmpeg -y -f lavfi -i "$TONE" "${COMMON_META[@]}" \
  -c:a libvorbis -q:a 5 "$FIX/08_sample.ogg"

# --- 09 AIFF ---
ffmpeg -y -f lavfi -i "$TONE" "${COMMON_META[@]}" \
  -c:a pcm_s16be "$FIX/09_sample.aiff"

# --- 10 FLAC with embedded cover art ---
ffmpeg -y -f lavfi -i "color=c=white:s=16x16:d=0.04" -frames:v 1 -q:v 2 -f mjpeg "$FIX/.cover.jpg"
ffmpeg -y -i "$FIX/01_flac_replaygain.flac" -i "$FIX/.cover.jpg" \
  -map 0:a -map 1:v -c:a copy -c:v mjpeg \
  -disposition:v attached_pic "$FIX/10_with_cover.flac"
rm -f "$FIX/.cover.jpg"

echo
echo "=== Generated ==="
ls -lh "$FIX"