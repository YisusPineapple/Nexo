/// Immutable snapshot of the app's build identity, as reported by the
/// platform (read at the Data layer via PackageInfo). Composed only
/// of already-well-formed platform strings — there is no cross-field
/// invariant to validate, so unlike Song or PlaybackQueue this stays
/// a plain immutable class instead of a Result-returning `create()`,
/// mirroring PlaybackSettings' own docstring on this exact point.
final class AppVersionInfo {
  const AppVersionInfo({
    required this.version,
    required this.buildNumber,
  });

  /// Semantic version without the build suffix, e.g. "0.0.11-beta".
  final String version;

  /// Build number, e.g. "55". Mirrors Android's versionCode and the
  /// `+N` suffix in pubspec.yaml.
  final String buildNumber;

  /// User-facing "0.0.11-beta+55" label, matching the exact format
  /// pubspec.yaml uses. This is the ONLY place that string format is
  /// assembled, so Presentation never hand-formats it again.
  String get displayLabel => '$version+$buildNumber';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppVersionInfo &&
          other.version == version &&
          other.buildNumber == buildNumber);

  @override
  int get hashCode => Object.hash(version, buildNumber);
}