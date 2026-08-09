// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SongsTable extends Songs with TableInfo<$SongsTable, SongRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SongsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _trackArtistIdMeta =
      const VerificationMeta('trackArtistId');
  @override
  late final GeneratedColumn<String> trackArtistId = GeneratedColumn<String>(
      'track_artist_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _albumArtistIdMeta =
      const VerificationMeta('albumArtistId');
  @override
  late final GeneratedColumn<String> albumArtistId = GeneratedColumn<String>(
      'album_artist_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _albumIdMeta =
      const VerificationMeta('albumId');
  @override
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
      'album_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _trackNumberMeta =
      const VerificationMeta('trackNumber');
  @override
  late final GeneratedColumn<int> trackNumber = GeneratedColumn<int>(
      'track_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _discNumberMeta =
      const VerificationMeta('discNumber');
  @override
  late final GeneratedColumn<int> discNumber = GeneratedColumn<int>(
      'disc_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<AudioFormat, String> format =
      GeneratedColumn<String>('format', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<AudioFormat>($SongsTable.$converterformat);
  static const VerificationMeta _fileSizeBytesMeta =
      const VerificationMeta('fileSizeBytes');
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
      'file_size_bytes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> genreNames =
      GeneratedColumn<String>('genre_names', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<String>>($SongsTable.$convertergenreNames);
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
      'year', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _coverArtPathMeta =
      const VerificationMeta('coverArtPath');
  @override
  late final GeneratedColumn<String> coverArtPath = GeneratedColumn<String>(
      'cover_art_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _leadingSilenceMsMeta =
      const VerificationMeta('leadingSilenceMs');
  @override
  late final GeneratedColumn<int> leadingSilenceMs = GeneratedColumn<int>(
      'leading_silence_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _trailingSilenceMsMeta =
      const VerificationMeta('trailingSilenceMs');
  @override
  late final GeneratedColumn<int> trailingSilenceMs = GeneratedColumn<int>(
      'trailing_silence_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _replayGainTrackDbMeta =
      const VerificationMeta('replayGainTrackDb');
  @override
  late final GeneratedColumn<double> replayGainTrackDb =
      GeneratedColumn<double>('replay_gain_track_db', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _replayGainAlbumDbMeta =
      const VerificationMeta('replayGainAlbumDb');
  @override
  late final GeneratedColumn<double> replayGainAlbumDb =
      GeneratedColumn<double>('replay_gain_album_db', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _dateAddedUtcMsMeta =
      const VerificationMeta('dateAddedUtcMs');
  @override
  late final GeneratedColumn<int> dateAddedUtcMs = GeneratedColumn<int>(
      'date_added_utc_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isMissingMeta =
      const VerificationMeta('isMissing');
  @override
  late final GeneratedColumn<bool> isMissing = GeneratedColumn<bool>(
      'is_missing', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_missing" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        trackArtistId,
        albumArtistId,
        albumId,
        trackNumber,
        discNumber,
        durationMs,
        filePath,
        format,
        fileSizeBytes,
        genreNames,
        year,
        coverArtPath,
        leadingSilenceMs,
        trailingSilenceMs,
        replayGainTrackDb,
        replayGainAlbumDb,
        dateAddedUtcMs,
        isMissing
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'songs';
  @override
  VerificationContext validateIntegrity(Insertable<SongRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('track_artist_id')) {
      context.handle(
          _trackArtistIdMeta,
          trackArtistId.isAcceptableOrUnknown(
              data['track_artist_id']!, _trackArtistIdMeta));
    } else if (isInserting) {
      context.missing(_trackArtistIdMeta);
    }
    if (data.containsKey('album_artist_id')) {
      context.handle(
          _albumArtistIdMeta,
          albumArtistId.isAcceptableOrUnknown(
              data['album_artist_id']!, _albumArtistIdMeta));
    }
    if (data.containsKey('album_id')) {
      context.handle(_albumIdMeta,
          albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta));
    }
    if (data.containsKey('track_number')) {
      context.handle(
          _trackNumberMeta,
          trackNumber.isAcceptableOrUnknown(
              data['track_number']!, _trackNumberMeta));
    }
    if (data.containsKey('disc_number')) {
      context.handle(
          _discNumberMeta,
          discNumber.isAcceptableOrUnknown(
              data['disc_number']!, _discNumberMeta));
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
          _fileSizeBytesMeta,
          fileSizeBytes.isAcceptableOrUnknown(
              data['file_size_bytes']!, _fileSizeBytesMeta));
    } else if (isInserting) {
      context.missing(_fileSizeBytesMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
          _yearMeta, year.isAcceptableOrUnknown(data['year']!, _yearMeta));
    }
    if (data.containsKey('cover_art_path')) {
      context.handle(
          _coverArtPathMeta,
          coverArtPath.isAcceptableOrUnknown(
              data['cover_art_path']!, _coverArtPathMeta));
    }
    if (data.containsKey('leading_silence_ms')) {
      context.handle(
          _leadingSilenceMsMeta,
          leadingSilenceMs.isAcceptableOrUnknown(
              data['leading_silence_ms']!, _leadingSilenceMsMeta));
    }
    if (data.containsKey('trailing_silence_ms')) {
      context.handle(
          _trailingSilenceMsMeta,
          trailingSilenceMs.isAcceptableOrUnknown(
              data['trailing_silence_ms']!, _trailingSilenceMsMeta));
    }
    if (data.containsKey('replay_gain_track_db')) {
      context.handle(
          _replayGainTrackDbMeta,
          replayGainTrackDb.isAcceptableOrUnknown(
              data['replay_gain_track_db']!, _replayGainTrackDbMeta));
    }
    if (data.containsKey('replay_gain_album_db')) {
      context.handle(
          _replayGainAlbumDbMeta,
          replayGainAlbumDb.isAcceptableOrUnknown(
              data['replay_gain_album_db']!, _replayGainAlbumDbMeta));
    }
    if (data.containsKey('date_added_utc_ms')) {
      context.handle(
          _dateAddedUtcMsMeta,
          dateAddedUtcMs.isAcceptableOrUnknown(
              data['date_added_utc_ms']!, _dateAddedUtcMsMeta));
    } else if (isInserting) {
      context.missing(_dateAddedUtcMsMeta);
    }
    if (data.containsKey('is_missing')) {
      context.handle(_isMissingMeta,
          isMissing.isAcceptableOrUnknown(data['is_missing']!, _isMissingMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SongRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SongRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      trackArtistId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}track_artist_id'])!,
      albumArtistId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album_artist_id']),
      albumId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}album_id']),
      trackNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}track_number']),
      discNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}disc_number']),
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms'])!,
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      format: $SongsTable.$converterformat.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}format'])!),
      fileSizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size_bytes'])!,
      genreNames: $SongsTable.$convertergenreNames.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}genre_names'])!),
      year: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}year']),
      coverArtPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_art_path']),
      leadingSilenceMs: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}leading_silence_ms'])!,
      trailingSilenceMs: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}trailing_silence_ms'])!,
      replayGainTrackDb: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}replay_gain_track_db']),
      replayGainAlbumDb: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}replay_gain_album_db']),
      dateAddedUtcMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}date_added_utc_ms'])!,
      isMissing: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_missing'])!,
    );
  }

  @override
  $SongsTable createAlias(String alias) {
    return $SongsTable(attachedDatabase, alias);
  }

  static TypeConverter<AudioFormat, String> $converterformat =
      const AudioFormatConverter();
  static TypeConverter<List<String>, String> $convertergenreNames =
      const StringListConverter();
}

class SongRow extends DataClass implements Insertable<SongRow> {
  final String id;
  final String title;
  final String trackArtistId;
  final String? albumArtistId;
  final String? albumId;
  final int? trackNumber;
  final int? discNumber;

  /// [Duration] stored as whole milliseconds. Deliberately a plain
  /// int, not drift's dateTime()-style column sugar: this is a
  /// duration, not a point in time, and a plain int sidesteps any
  /// version-specific behavior in how drift's temporal columns pick
  /// their on-disk representation.
  final int durationMs;
  final String filePath;
  final AudioFormat format;
  final int fileSizeBytes;

  /// See [StringListConverter]'s docstring for why this is one column,
  /// not a join table.
  final List<String> genreNames;
  final int? year;
  final String? coverArtPath;
  final int leadingSilenceMs;
  final int trailingSilenceMs;
  final double? replayGainTrackDb;
  final double? replayGainAlbumDb;

  /// Epoch milliseconds, UTC — see [durationMs]'s docstring for the
  /// same "plain int, not a temporal column type" reasoning.
  final int dateAddedUtcMs;
  final bool isMissing;
  const SongRow(
      {required this.id,
      required this.title,
      required this.trackArtistId,
      this.albumArtistId,
      this.albumId,
      this.trackNumber,
      this.discNumber,
      required this.durationMs,
      required this.filePath,
      required this.format,
      required this.fileSizeBytes,
      required this.genreNames,
      this.year,
      this.coverArtPath,
      required this.leadingSilenceMs,
      required this.trailingSilenceMs,
      this.replayGainTrackDb,
      this.replayGainAlbumDb,
      required this.dateAddedUtcMs,
      required this.isMissing});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['track_artist_id'] = Variable<String>(trackArtistId);
    if (!nullToAbsent || albumArtistId != null) {
      map['album_artist_id'] = Variable<String>(albumArtistId);
    }
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<String>(albumId);
    }
    if (!nullToAbsent || trackNumber != null) {
      map['track_number'] = Variable<int>(trackNumber);
    }
    if (!nullToAbsent || discNumber != null) {
      map['disc_number'] = Variable<int>(discNumber);
    }
    map['duration_ms'] = Variable<int>(durationMs);
    map['file_path'] = Variable<String>(filePath);
    {
      map['format'] =
          Variable<String>($SongsTable.$converterformat.toSql(format));
    }
    map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    {
      map['genre_names'] =
          Variable<String>($SongsTable.$convertergenreNames.toSql(genreNames));
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || coverArtPath != null) {
      map['cover_art_path'] = Variable<String>(coverArtPath);
    }
    map['leading_silence_ms'] = Variable<int>(leadingSilenceMs);
    map['trailing_silence_ms'] = Variable<int>(trailingSilenceMs);
    if (!nullToAbsent || replayGainTrackDb != null) {
      map['replay_gain_track_db'] = Variable<double>(replayGainTrackDb);
    }
    if (!nullToAbsent || replayGainAlbumDb != null) {
      map['replay_gain_album_db'] = Variable<double>(replayGainAlbumDb);
    }
    map['date_added_utc_ms'] = Variable<int>(dateAddedUtcMs);
    map['is_missing'] = Variable<bool>(isMissing);
    return map;
  }

  SongsCompanion toCompanion(bool nullToAbsent) {
    return SongsCompanion(
      id: Value(id),
      title: Value(title),
      trackArtistId: Value(trackArtistId),
      albumArtistId: albumArtistId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumArtistId),
      albumId: albumId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumId),
      trackNumber: trackNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(trackNumber),
      discNumber: discNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(discNumber),
      durationMs: Value(durationMs),
      filePath: Value(filePath),
      format: Value(format),
      fileSizeBytes: Value(fileSizeBytes),
      genreNames: Value(genreNames),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      coverArtPath: coverArtPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverArtPath),
      leadingSilenceMs: Value(leadingSilenceMs),
      trailingSilenceMs: Value(trailingSilenceMs),
      replayGainTrackDb: replayGainTrackDb == null && nullToAbsent
          ? const Value.absent()
          : Value(replayGainTrackDb),
      replayGainAlbumDb: replayGainAlbumDb == null && nullToAbsent
          ? const Value.absent()
          : Value(replayGainAlbumDb),
      dateAddedUtcMs: Value(dateAddedUtcMs),
      isMissing: Value(isMissing),
    );
  }

  factory SongRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SongRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      trackArtistId: serializer.fromJson<String>(json['trackArtistId']),
      albumArtistId: serializer.fromJson<String?>(json['albumArtistId']),
      albumId: serializer.fromJson<String?>(json['albumId']),
      trackNumber: serializer.fromJson<int?>(json['trackNumber']),
      discNumber: serializer.fromJson<int?>(json['discNumber']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      filePath: serializer.fromJson<String>(json['filePath']),
      format: serializer.fromJson<AudioFormat>(json['format']),
      fileSizeBytes: serializer.fromJson<int>(json['fileSizeBytes']),
      genreNames: serializer.fromJson<List<String>>(json['genreNames']),
      year: serializer.fromJson<int?>(json['year']),
      coverArtPath: serializer.fromJson<String?>(json['coverArtPath']),
      leadingSilenceMs: serializer.fromJson<int>(json['leadingSilenceMs']),
      trailingSilenceMs: serializer.fromJson<int>(json['trailingSilenceMs']),
      replayGainTrackDb:
          serializer.fromJson<double?>(json['replayGainTrackDb']),
      replayGainAlbumDb:
          serializer.fromJson<double?>(json['replayGainAlbumDb']),
      dateAddedUtcMs: serializer.fromJson<int>(json['dateAddedUtcMs']),
      isMissing: serializer.fromJson<bool>(json['isMissing']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'trackArtistId': serializer.toJson<String>(trackArtistId),
      'albumArtistId': serializer.toJson<String?>(albumArtistId),
      'albumId': serializer.toJson<String?>(albumId),
      'trackNumber': serializer.toJson<int?>(trackNumber),
      'discNumber': serializer.toJson<int?>(discNumber),
      'durationMs': serializer.toJson<int>(durationMs),
      'filePath': serializer.toJson<String>(filePath),
      'format': serializer.toJson<AudioFormat>(format),
      'fileSizeBytes': serializer.toJson<int>(fileSizeBytes),
      'genreNames': serializer.toJson<List<String>>(genreNames),
      'year': serializer.toJson<int?>(year),
      'coverArtPath': serializer.toJson<String?>(coverArtPath),
      'leadingSilenceMs': serializer.toJson<int>(leadingSilenceMs),
      'trailingSilenceMs': serializer.toJson<int>(trailingSilenceMs),
      'replayGainTrackDb': serializer.toJson<double?>(replayGainTrackDb),
      'replayGainAlbumDb': serializer.toJson<double?>(replayGainAlbumDb),
      'dateAddedUtcMs': serializer.toJson<int>(dateAddedUtcMs),
      'isMissing': serializer.toJson<bool>(isMissing),
    };
  }

  SongRow copyWith(
          {String? id,
          String? title,
          String? trackArtistId,
          Value<String?> albumArtistId = const Value.absent(),
          Value<String?> albumId = const Value.absent(),
          Value<int?> trackNumber = const Value.absent(),
          Value<int?> discNumber = const Value.absent(),
          int? durationMs,
          String? filePath,
          AudioFormat? format,
          int? fileSizeBytes,
          List<String>? genreNames,
          Value<int?> year = const Value.absent(),
          Value<String?> coverArtPath = const Value.absent(),
          int? leadingSilenceMs,
          int? trailingSilenceMs,
          Value<double?> replayGainTrackDb = const Value.absent(),
          Value<double?> replayGainAlbumDb = const Value.absent(),
          int? dateAddedUtcMs,
          bool? isMissing}) =>
      SongRow(
        id: id ?? this.id,
        title: title ?? this.title,
        trackArtistId: trackArtistId ?? this.trackArtistId,
        albumArtistId:
            albumArtistId.present ? albumArtistId.value : this.albumArtistId,
        albumId: albumId.present ? albumId.value : this.albumId,
        trackNumber: trackNumber.present ? trackNumber.value : this.trackNumber,
        discNumber: discNumber.present ? discNumber.value : this.discNumber,
        durationMs: durationMs ?? this.durationMs,
        filePath: filePath ?? this.filePath,
        format: format ?? this.format,
        fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
        genreNames: genreNames ?? this.genreNames,
        year: year.present ? year.value : this.year,
        coverArtPath:
            coverArtPath.present ? coverArtPath.value : this.coverArtPath,
        leadingSilenceMs: leadingSilenceMs ?? this.leadingSilenceMs,
        trailingSilenceMs: trailingSilenceMs ?? this.trailingSilenceMs,
        replayGainTrackDb: replayGainTrackDb.present
            ? replayGainTrackDb.value
            : this.replayGainTrackDb,
        replayGainAlbumDb: replayGainAlbumDb.present
            ? replayGainAlbumDb.value
            : this.replayGainAlbumDb,
        dateAddedUtcMs: dateAddedUtcMs ?? this.dateAddedUtcMs,
        isMissing: isMissing ?? this.isMissing,
      );
  SongRow copyWithCompanion(SongsCompanion data) {
    return SongRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      trackArtistId: data.trackArtistId.present
          ? data.trackArtistId.value
          : this.trackArtistId,
      albumArtistId: data.albumArtistId.present
          ? data.albumArtistId.value
          : this.albumArtistId,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      trackNumber:
          data.trackNumber.present ? data.trackNumber.value : this.trackNumber,
      discNumber:
          data.discNumber.present ? data.discNumber.value : this.discNumber,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      format: data.format.present ? data.format.value : this.format,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      genreNames:
          data.genreNames.present ? data.genreNames.value : this.genreNames,
      year: data.year.present ? data.year.value : this.year,
      coverArtPath: data.coverArtPath.present
          ? data.coverArtPath.value
          : this.coverArtPath,
      leadingSilenceMs: data.leadingSilenceMs.present
          ? data.leadingSilenceMs.value
          : this.leadingSilenceMs,
      trailingSilenceMs: data.trailingSilenceMs.present
          ? data.trailingSilenceMs.value
          : this.trailingSilenceMs,
      replayGainTrackDb: data.replayGainTrackDb.present
          ? data.replayGainTrackDb.value
          : this.replayGainTrackDb,
      replayGainAlbumDb: data.replayGainAlbumDb.present
          ? data.replayGainAlbumDb.value
          : this.replayGainAlbumDb,
      dateAddedUtcMs: data.dateAddedUtcMs.present
          ? data.dateAddedUtcMs.value
          : this.dateAddedUtcMs,
      isMissing: data.isMissing.present ? data.isMissing.value : this.isMissing,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SongRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('trackArtistId: $trackArtistId, ')
          ..write('albumArtistId: $albumArtistId, ')
          ..write('albumId: $albumId, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('discNumber: $discNumber, ')
          ..write('durationMs: $durationMs, ')
          ..write('filePath: $filePath, ')
          ..write('format: $format, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('genreNames: $genreNames, ')
          ..write('year: $year, ')
          ..write('coverArtPath: $coverArtPath, ')
          ..write('leadingSilenceMs: $leadingSilenceMs, ')
          ..write('trailingSilenceMs: $trailingSilenceMs, ')
          ..write('replayGainTrackDb: $replayGainTrackDb, ')
          ..write('replayGainAlbumDb: $replayGainAlbumDb, ')
          ..write('dateAddedUtcMs: $dateAddedUtcMs, ')
          ..write('isMissing: $isMissing')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      trackArtistId,
      albumArtistId,
      albumId,
      trackNumber,
      discNumber,
      durationMs,
      filePath,
      format,
      fileSizeBytes,
      genreNames,
      year,
      coverArtPath,
      leadingSilenceMs,
      trailingSilenceMs,
      replayGainTrackDb,
      replayGainAlbumDb,
      dateAddedUtcMs,
      isMissing);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SongRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.trackArtistId == this.trackArtistId &&
          other.albumArtistId == this.albumArtistId &&
          other.albumId == this.albumId &&
          other.trackNumber == this.trackNumber &&
          other.discNumber == this.discNumber &&
          other.durationMs == this.durationMs &&
          other.filePath == this.filePath &&
          other.format == this.format &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.genreNames == this.genreNames &&
          other.year == this.year &&
          other.coverArtPath == this.coverArtPath &&
          other.leadingSilenceMs == this.leadingSilenceMs &&
          other.trailingSilenceMs == this.trailingSilenceMs &&
          other.replayGainTrackDb == this.replayGainTrackDb &&
          other.replayGainAlbumDb == this.replayGainAlbumDb &&
          other.dateAddedUtcMs == this.dateAddedUtcMs &&
          other.isMissing == this.isMissing);
}

class SongsCompanion extends UpdateCompanion<SongRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> trackArtistId;
  final Value<String?> albumArtistId;
  final Value<String?> albumId;
  final Value<int?> trackNumber;
  final Value<int?> discNumber;
  final Value<int> durationMs;
  final Value<String> filePath;
  final Value<AudioFormat> format;
  final Value<int> fileSizeBytes;
  final Value<List<String>> genreNames;
  final Value<int?> year;
  final Value<String?> coverArtPath;
  final Value<int> leadingSilenceMs;
  final Value<int> trailingSilenceMs;
  final Value<double?> replayGainTrackDb;
  final Value<double?> replayGainAlbumDb;
  final Value<int> dateAddedUtcMs;
  final Value<bool> isMissing;
  final Value<int> rowid;
  const SongsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.trackArtistId = const Value.absent(),
    this.albumArtistId = const Value.absent(),
    this.albumId = const Value.absent(),
    this.trackNumber = const Value.absent(),
    this.discNumber = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.filePath = const Value.absent(),
    this.format = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.genreNames = const Value.absent(),
    this.year = const Value.absent(),
    this.coverArtPath = const Value.absent(),
    this.leadingSilenceMs = const Value.absent(),
    this.trailingSilenceMs = const Value.absent(),
    this.replayGainTrackDb = const Value.absent(),
    this.replayGainAlbumDb = const Value.absent(),
    this.dateAddedUtcMs = const Value.absent(),
    this.isMissing = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SongsCompanion.insert({
    required String id,
    required String title,
    required String trackArtistId,
    this.albumArtistId = const Value.absent(),
    this.albumId = const Value.absent(),
    this.trackNumber = const Value.absent(),
    this.discNumber = const Value.absent(),
    required int durationMs,
    required String filePath,
    required AudioFormat format,
    required int fileSizeBytes,
    required List<String> genreNames,
    this.year = const Value.absent(),
    this.coverArtPath = const Value.absent(),
    this.leadingSilenceMs = const Value.absent(),
    this.trailingSilenceMs = const Value.absent(),
    this.replayGainTrackDb = const Value.absent(),
    this.replayGainAlbumDb = const Value.absent(),
    required int dateAddedUtcMs,
    this.isMissing = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        trackArtistId = Value(trackArtistId),
        durationMs = Value(durationMs),
        filePath = Value(filePath),
        format = Value(format),
        fileSizeBytes = Value(fileSizeBytes),
        genreNames = Value(genreNames),
        dateAddedUtcMs = Value(dateAddedUtcMs);
  static Insertable<SongRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? trackArtistId,
    Expression<String>? albumArtistId,
    Expression<String>? albumId,
    Expression<int>? trackNumber,
    Expression<int>? discNumber,
    Expression<int>? durationMs,
    Expression<String>? filePath,
    Expression<String>? format,
    Expression<int>? fileSizeBytes,
    Expression<String>? genreNames,
    Expression<int>? year,
    Expression<String>? coverArtPath,
    Expression<int>? leadingSilenceMs,
    Expression<int>? trailingSilenceMs,
    Expression<double>? replayGainTrackDb,
    Expression<double>? replayGainAlbumDb,
    Expression<int>? dateAddedUtcMs,
    Expression<bool>? isMissing,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (trackArtistId != null) 'track_artist_id': trackArtistId,
      if (albumArtistId != null) 'album_artist_id': albumArtistId,
      if (albumId != null) 'album_id': albumId,
      if (trackNumber != null) 'track_number': trackNumber,
      if (discNumber != null) 'disc_number': discNumber,
      if (durationMs != null) 'duration_ms': durationMs,
      if (filePath != null) 'file_path': filePath,
      if (format != null) 'format': format,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (genreNames != null) 'genre_names': genreNames,
      if (year != null) 'year': year,
      if (coverArtPath != null) 'cover_art_path': coverArtPath,
      if (leadingSilenceMs != null) 'leading_silence_ms': leadingSilenceMs,
      if (trailingSilenceMs != null) 'trailing_silence_ms': trailingSilenceMs,
      if (replayGainTrackDb != null) 'replay_gain_track_db': replayGainTrackDb,
      if (replayGainAlbumDb != null) 'replay_gain_album_db': replayGainAlbumDb,
      if (dateAddedUtcMs != null) 'date_added_utc_ms': dateAddedUtcMs,
      if (isMissing != null) 'is_missing': isMissing,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SongsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? trackArtistId,
      Value<String?>? albumArtistId,
      Value<String?>? albumId,
      Value<int?>? trackNumber,
      Value<int?>? discNumber,
      Value<int>? durationMs,
      Value<String>? filePath,
      Value<AudioFormat>? format,
      Value<int>? fileSizeBytes,
      Value<List<String>>? genreNames,
      Value<int?>? year,
      Value<String?>? coverArtPath,
      Value<int>? leadingSilenceMs,
      Value<int>? trailingSilenceMs,
      Value<double?>? replayGainTrackDb,
      Value<double?>? replayGainAlbumDb,
      Value<int>? dateAddedUtcMs,
      Value<bool>? isMissing,
      Value<int>? rowid}) {
    return SongsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      trackArtistId: trackArtistId ?? this.trackArtistId,
      albumArtistId: albumArtistId ?? this.albumArtistId,
      albumId: albumId ?? this.albumId,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      durationMs: durationMs ?? this.durationMs,
      filePath: filePath ?? this.filePath,
      format: format ?? this.format,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      genreNames: genreNames ?? this.genreNames,
      year: year ?? this.year,
      coverArtPath: coverArtPath ?? this.coverArtPath,
      leadingSilenceMs: leadingSilenceMs ?? this.leadingSilenceMs,
      trailingSilenceMs: trailingSilenceMs ?? this.trailingSilenceMs,
      replayGainTrackDb: replayGainTrackDb ?? this.replayGainTrackDb,
      replayGainAlbumDb: replayGainAlbumDb ?? this.replayGainAlbumDb,
      dateAddedUtcMs: dateAddedUtcMs ?? this.dateAddedUtcMs,
      isMissing: isMissing ?? this.isMissing,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (trackArtistId.present) {
      map['track_artist_id'] = Variable<String>(trackArtistId.value);
    }
    if (albumArtistId.present) {
      map['album_artist_id'] = Variable<String>(albumArtistId.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    if (trackNumber.present) {
      map['track_number'] = Variable<int>(trackNumber.value);
    }
    if (discNumber.present) {
      map['disc_number'] = Variable<int>(discNumber.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (format.present) {
      map['format'] =
          Variable<String>($SongsTable.$converterformat.toSql(format.value));
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (genreNames.present) {
      map['genre_names'] = Variable<String>(
          $SongsTable.$convertergenreNames.toSql(genreNames.value));
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (coverArtPath.present) {
      map['cover_art_path'] = Variable<String>(coverArtPath.value);
    }
    if (leadingSilenceMs.present) {
      map['leading_silence_ms'] = Variable<int>(leadingSilenceMs.value);
    }
    if (trailingSilenceMs.present) {
      map['trailing_silence_ms'] = Variable<int>(trailingSilenceMs.value);
    }
    if (replayGainTrackDb.present) {
      map['replay_gain_track_db'] = Variable<double>(replayGainTrackDb.value);
    }
    if (replayGainAlbumDb.present) {
      map['replay_gain_album_db'] = Variable<double>(replayGainAlbumDb.value);
    }
    if (dateAddedUtcMs.present) {
      map['date_added_utc_ms'] = Variable<int>(dateAddedUtcMs.value);
    }
    if (isMissing.present) {
      map['is_missing'] = Variable<bool>(isMissing.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SongsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('trackArtistId: $trackArtistId, ')
          ..write('albumArtistId: $albumArtistId, ')
          ..write('albumId: $albumId, ')
          ..write('trackNumber: $trackNumber, ')
          ..write('discNumber: $discNumber, ')
          ..write('durationMs: $durationMs, ')
          ..write('filePath: $filePath, ')
          ..write('format: $format, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('genreNames: $genreNames, ')
          ..write('year: $year, ')
          ..write('coverArtPath: $coverArtPath, ')
          ..write('leadingSilenceMs: $leadingSilenceMs, ')
          ..write('trailingSilenceMs: $trailingSilenceMs, ')
          ..write('replayGainTrackDb: $replayGainTrackDb, ')
          ..write('replayGainAlbumDb: $replayGainAlbumDb, ')
          ..write('dateAddedUtcMs: $dateAddedUtcMs, ')
          ..write('isMissing: $isMissing, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaybackQueuesTable extends PlaybackQueues
    with TableInfo<$PlaybackQueuesTable, PlaybackQueueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaybackQueuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currentIndexMeta =
      const VerificationMeta('currentIndex');
  @override
  late final GeneratedColumn<int> currentIndex = GeneratedColumn<int>(
      'current_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<RepeatMode, String> repeatMode =
      GeneratedColumn<String>('repeat_mode', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<RepeatMode>($PlaybackQueuesTable.$converterrepeatMode);
  @override
  late final GeneratedColumnWithTypeConverter<QueueSource, String> source =
      GeneratedColumn<String>('source', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<QueueSource>($PlaybackQueuesTable.$convertersource);
  static const VerificationMeta _shuffleEnabledMeta =
      const VerificationMeta('shuffleEnabled');
  @override
  late final GeneratedColumn<bool> shuffleEnabled = GeneratedColumn<bool>(
      'shuffle_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("shuffle_enabled" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _preShuffleCurrentIndexMeta =
      const VerificationMeta('preShuffleCurrentIndex');
  @override
  late final GeneratedColumn<int> preShuffleCurrentIndex = GeneratedColumn<int>(
      'pre_shuffle_current_index', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        currentIndex,
        repeatMode,
        source,
        shuffleEnabled,
        preShuffleCurrentIndex
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playback_queues';
  @override
  VerificationContext validateIntegrity(Insertable<PlaybackQueueRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('current_index')) {
      context.handle(
          _currentIndexMeta,
          currentIndex.isAcceptableOrUnknown(
              data['current_index']!, _currentIndexMeta));
    } else if (isInserting) {
      context.missing(_currentIndexMeta);
    }
    if (data.containsKey('shuffle_enabled')) {
      context.handle(
          _shuffleEnabledMeta,
          shuffleEnabled.isAcceptableOrUnknown(
              data['shuffle_enabled']!, _shuffleEnabledMeta));
    }
    if (data.containsKey('pre_shuffle_current_index')) {
      context.handle(
          _preShuffleCurrentIndexMeta,
          preShuffleCurrentIndex.isAcceptableOrUnknown(
              data['pre_shuffle_current_index']!, _preShuffleCurrentIndexMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaybackQueueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaybackQueueRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      currentIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}current_index'])!,
      repeatMode: $PlaybackQueuesTable.$converterrepeatMode.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}repeat_mode'])!),
      source: $PlaybackQueuesTable.$convertersource.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!),
      shuffleEnabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}shuffle_enabled'])!,
      preShuffleCurrentIndex: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}pre_shuffle_current_index']),
    );
  }

  @override
  $PlaybackQueuesTable createAlias(String alias) {
    return $PlaybackQueuesTable(attachedDatabase, alias);
  }

  static TypeConverter<RepeatMode, String> $converterrepeatMode =
      const RepeatModeConverter();
  static TypeConverter<QueueSource, String> $convertersource =
      const QueueSourceConverter();
}

class PlaybackQueueRow extends DataClass
    implements Insertable<PlaybackQueueRow> {
  final String id;

  /// Mirrors [PlaybackQueue.currentIndex] exactly, including its -1
  /// double meaning (empty queue OR a queue that finished with
  /// RepeatMode.off) — read that field's Domain docstring before
  /// touching this column or any code that writes to it.
  final int currentIndex;
  final RepeatMode repeatMode;
  final QueueSource source;
  final bool shuffleEnabled;

  /// Non-null only while [shuffleEnabled] is true — mirrors
  /// [PlaybackQueue.preShuffleCurrentIndex] exactly.
  final int? preShuffleCurrentIndex;
  const PlaybackQueueRow(
      {required this.id,
      required this.currentIndex,
      required this.repeatMode,
      required this.source,
      required this.shuffleEnabled,
      this.preShuffleCurrentIndex});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['current_index'] = Variable<int>(currentIndex);
    {
      map['repeat_mode'] = Variable<String>(
          $PlaybackQueuesTable.$converterrepeatMode.toSql(repeatMode));
    }
    {
      map['source'] =
          Variable<String>($PlaybackQueuesTable.$convertersource.toSql(source));
    }
    map['shuffle_enabled'] = Variable<bool>(shuffleEnabled);
    if (!nullToAbsent || preShuffleCurrentIndex != null) {
      map['pre_shuffle_current_index'] = Variable<int>(preShuffleCurrentIndex);
    }
    return map;
  }

  PlaybackQueuesCompanion toCompanion(bool nullToAbsent) {
    return PlaybackQueuesCompanion(
      id: Value(id),
      currentIndex: Value(currentIndex),
      repeatMode: Value(repeatMode),
      source: Value(source),
      shuffleEnabled: Value(shuffleEnabled),
      preShuffleCurrentIndex: preShuffleCurrentIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(preShuffleCurrentIndex),
    );
  }

  factory PlaybackQueueRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaybackQueueRow(
      id: serializer.fromJson<String>(json['id']),
      currentIndex: serializer.fromJson<int>(json['currentIndex']),
      repeatMode: serializer.fromJson<RepeatMode>(json['repeatMode']),
      source: serializer.fromJson<QueueSource>(json['source']),
      shuffleEnabled: serializer.fromJson<bool>(json['shuffleEnabled']),
      preShuffleCurrentIndex:
          serializer.fromJson<int?>(json['preShuffleCurrentIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'currentIndex': serializer.toJson<int>(currentIndex),
      'repeatMode': serializer.toJson<RepeatMode>(repeatMode),
      'source': serializer.toJson<QueueSource>(source),
      'shuffleEnabled': serializer.toJson<bool>(shuffleEnabled),
      'preShuffleCurrentIndex': serializer.toJson<int?>(preShuffleCurrentIndex),
    };
  }

  PlaybackQueueRow copyWith(
          {String? id,
          int? currentIndex,
          RepeatMode? repeatMode,
          QueueSource? source,
          bool? shuffleEnabled,
          Value<int?> preShuffleCurrentIndex = const Value.absent()}) =>
      PlaybackQueueRow(
        id: id ?? this.id,
        currentIndex: currentIndex ?? this.currentIndex,
        repeatMode: repeatMode ?? this.repeatMode,
        source: source ?? this.source,
        shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
        preShuffleCurrentIndex: preShuffleCurrentIndex.present
            ? preShuffleCurrentIndex.value
            : this.preShuffleCurrentIndex,
      );
  PlaybackQueueRow copyWithCompanion(PlaybackQueuesCompanion data) {
    return PlaybackQueueRow(
      id: data.id.present ? data.id.value : this.id,
      currentIndex: data.currentIndex.present
          ? data.currentIndex.value
          : this.currentIndex,
      repeatMode:
          data.repeatMode.present ? data.repeatMode.value : this.repeatMode,
      source: data.source.present ? data.source.value : this.source,
      shuffleEnabled: data.shuffleEnabled.present
          ? data.shuffleEnabled.value
          : this.shuffleEnabled,
      preShuffleCurrentIndex: data.preShuffleCurrentIndex.present
          ? data.preShuffleCurrentIndex.value
          : this.preShuffleCurrentIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackQueueRow(')
          ..write('id: $id, ')
          ..write('currentIndex: $currentIndex, ')
          ..write('repeatMode: $repeatMode, ')
          ..write('source: $source, ')
          ..write('shuffleEnabled: $shuffleEnabled, ')
          ..write('preShuffleCurrentIndex: $preShuffleCurrentIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, currentIndex, repeatMode, source,
      shuffleEnabled, preShuffleCurrentIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackQueueRow &&
          other.id == this.id &&
          other.currentIndex == this.currentIndex &&
          other.repeatMode == this.repeatMode &&
          other.source == this.source &&
          other.shuffleEnabled == this.shuffleEnabled &&
          other.preShuffleCurrentIndex == this.preShuffleCurrentIndex);
}

class PlaybackQueuesCompanion extends UpdateCompanion<PlaybackQueueRow> {
  final Value<String> id;
  final Value<int> currentIndex;
  final Value<RepeatMode> repeatMode;
  final Value<QueueSource> source;
  final Value<bool> shuffleEnabled;
  final Value<int?> preShuffleCurrentIndex;
  final Value<int> rowid;
  const PlaybackQueuesCompanion({
    this.id = const Value.absent(),
    this.currentIndex = const Value.absent(),
    this.repeatMode = const Value.absent(),
    this.source = const Value.absent(),
    this.shuffleEnabled = const Value.absent(),
    this.preShuffleCurrentIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaybackQueuesCompanion.insert({
    required String id,
    required int currentIndex,
    required RepeatMode repeatMode,
    required QueueSource source,
    this.shuffleEnabled = const Value.absent(),
    this.preShuffleCurrentIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        currentIndex = Value(currentIndex),
        repeatMode = Value(repeatMode),
        source = Value(source);
  static Insertable<PlaybackQueueRow> custom({
    Expression<String>? id,
    Expression<int>? currentIndex,
    Expression<String>? repeatMode,
    Expression<String>? source,
    Expression<bool>? shuffleEnabled,
    Expression<int>? preShuffleCurrentIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currentIndex != null) 'current_index': currentIndex,
      if (repeatMode != null) 'repeat_mode': repeatMode,
      if (source != null) 'source': source,
      if (shuffleEnabled != null) 'shuffle_enabled': shuffleEnabled,
      if (preShuffleCurrentIndex != null)
        'pre_shuffle_current_index': preShuffleCurrentIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaybackQueuesCompanion copyWith(
      {Value<String>? id,
      Value<int>? currentIndex,
      Value<RepeatMode>? repeatMode,
      Value<QueueSource>? source,
      Value<bool>? shuffleEnabled,
      Value<int?>? preShuffleCurrentIndex,
      Value<int>? rowid}) {
    return PlaybackQueuesCompanion(
      id: id ?? this.id,
      currentIndex: currentIndex ?? this.currentIndex,
      repeatMode: repeatMode ?? this.repeatMode,
      source: source ?? this.source,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      preShuffleCurrentIndex:
          preShuffleCurrentIndex ?? this.preShuffleCurrentIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (currentIndex.present) {
      map['current_index'] = Variable<int>(currentIndex.value);
    }
    if (repeatMode.present) {
      map['repeat_mode'] = Variable<String>(
          $PlaybackQueuesTable.$converterrepeatMode.toSql(repeatMode.value));
    }
    if (source.present) {
      map['source'] = Variable<String>(
          $PlaybackQueuesTable.$convertersource.toSql(source.value));
    }
    if (shuffleEnabled.present) {
      map['shuffle_enabled'] = Variable<bool>(shuffleEnabled.value);
    }
    if (preShuffleCurrentIndex.present) {
      map['pre_shuffle_current_index'] =
          Variable<int>(preShuffleCurrentIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackQueuesCompanion(')
          ..write('id: $id, ')
          ..write('currentIndex: $currentIndex, ')
          ..write('repeatMode: $repeatMode, ')
          ..write('source: $source, ')
          ..write('shuffleEnabled: $shuffleEnabled, ')
          ..write('preShuffleCurrentIndex: $preShuffleCurrentIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QueueSongsTable extends QueueSongs
    with TableInfo<$QueueSongsTable, QueueSongRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QueueSongsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _queueIdMeta =
      const VerificationMeta('queueId');
  @override
  late final GeneratedColumn<String> queueId = GeneratedColumn<String>(
      'queue_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES playback_queues (id)'));
  static const VerificationMeta _listKindMeta =
      const VerificationMeta('listKind');
  @override
  late final GeneratedColumn<String> listKind = GeneratedColumn<String>(
      'list_kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<String> songId = GeneratedColumn<String>(
      'song_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES songs (id)'));
  @override
  List<GeneratedColumn> get $columns => [queueId, listKind, position, songId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'queue_songs';
  @override
  VerificationContext validateIntegrity(Insertable<QueueSongRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('queue_id')) {
      context.handle(_queueIdMeta,
          queueId.isAcceptableOrUnknown(data['queue_id']!, _queueIdMeta));
    } else if (isInserting) {
      context.missing(_queueIdMeta);
    }
    if (data.containsKey('list_kind')) {
      context.handle(_listKindMeta,
          listKind.isAcceptableOrUnknown(data['list_kind']!, _listKindMeta));
    } else if (isInserting) {
      context.missing(_listKindMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('song_id')) {
      context.handle(_songIdMeta,
          songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta));
    } else if (isInserting) {
      context.missing(_songIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {queueId, listKind, position};
  @override
  QueueSongRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QueueSongRow(
      queueId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}queue_id'])!,
      listKind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}list_kind'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      songId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}song_id'])!,
    );
  }

  @override
  $QueueSongsTable createAlias(String alias) {
    return $QueueSongsTable(attachedDatabase, alias);
  }
}

class QueueSongRow extends DataClass implements Insertable<QueueSongRow> {
  final String queueId;

  /// 'current' or 'preShuffle'. Plain String, not a converted enum:
  /// this is Data-layer-only plumbing with no Domain-side equivalent
  /// type, so a converter would be ceremony around two literals.
  final String listKind;
  final int position;
  final String songId;
  const QueueSongRow(
      {required this.queueId,
      required this.listKind,
      required this.position,
      required this.songId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['queue_id'] = Variable<String>(queueId);
    map['list_kind'] = Variable<String>(listKind);
    map['position'] = Variable<int>(position);
    map['song_id'] = Variable<String>(songId);
    return map;
  }

  QueueSongsCompanion toCompanion(bool nullToAbsent) {
    return QueueSongsCompanion(
      queueId: Value(queueId),
      listKind: Value(listKind),
      position: Value(position),
      songId: Value(songId),
    );
  }

  factory QueueSongRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QueueSongRow(
      queueId: serializer.fromJson<String>(json['queueId']),
      listKind: serializer.fromJson<String>(json['listKind']),
      position: serializer.fromJson<int>(json['position']),
      songId: serializer.fromJson<String>(json['songId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'queueId': serializer.toJson<String>(queueId),
      'listKind': serializer.toJson<String>(listKind),
      'position': serializer.toJson<int>(position),
      'songId': serializer.toJson<String>(songId),
    };
  }

  QueueSongRow copyWith(
          {String? queueId, String? listKind, int? position, String? songId}) =>
      QueueSongRow(
        queueId: queueId ?? this.queueId,
        listKind: listKind ?? this.listKind,
        position: position ?? this.position,
        songId: songId ?? this.songId,
      );
  QueueSongRow copyWithCompanion(QueueSongsCompanion data) {
    return QueueSongRow(
      queueId: data.queueId.present ? data.queueId.value : this.queueId,
      listKind: data.listKind.present ? data.listKind.value : this.listKind,
      position: data.position.present ? data.position.value : this.position,
      songId: data.songId.present ? data.songId.value : this.songId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QueueSongRow(')
          ..write('queueId: $queueId, ')
          ..write('listKind: $listKind, ')
          ..write('position: $position, ')
          ..write('songId: $songId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(queueId, listKind, position, songId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QueueSongRow &&
          other.queueId == this.queueId &&
          other.listKind == this.listKind &&
          other.position == this.position &&
          other.songId == this.songId);
}

class QueueSongsCompanion extends UpdateCompanion<QueueSongRow> {
  final Value<String> queueId;
  final Value<String> listKind;
  final Value<int> position;
  final Value<String> songId;
  final Value<int> rowid;
  const QueueSongsCompanion({
    this.queueId = const Value.absent(),
    this.listKind = const Value.absent(),
    this.position = const Value.absent(),
    this.songId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QueueSongsCompanion.insert({
    required String queueId,
    required String listKind,
    required int position,
    required String songId,
    this.rowid = const Value.absent(),
  })  : queueId = Value(queueId),
        listKind = Value(listKind),
        position = Value(position),
        songId = Value(songId);
  static Insertable<QueueSongRow> custom({
    Expression<String>? queueId,
    Expression<String>? listKind,
    Expression<int>? position,
    Expression<String>? songId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (queueId != null) 'queue_id': queueId,
      if (listKind != null) 'list_kind': listKind,
      if (position != null) 'position': position,
      if (songId != null) 'song_id': songId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QueueSongsCompanion copyWith(
      {Value<String>? queueId,
      Value<String>? listKind,
      Value<int>? position,
      Value<String>? songId,
      Value<int>? rowid}) {
    return QueueSongsCompanion(
      queueId: queueId ?? this.queueId,
      listKind: listKind ?? this.listKind,
      position: position ?? this.position,
      songId: songId ?? this.songId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (queueId.present) {
      map['queue_id'] = Variable<String>(queueId.value);
    }
    if (listKind.present) {
      map['list_kind'] = Variable<String>(listKind.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (songId.present) {
      map['song_id'] = Variable<String>(songId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QueueSongsCompanion(')
          ..write('queueId: $queueId, ')
          ..write('listKind: $listKind, ')
          ..write('position: $position, ')
          ..write('songId: $songId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaybackSettingsTableTable extends PlaybackSettingsTable
    with TableInfo<$PlaybackSettingsTableTable, PlaybackSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaybackSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  late final GeneratedColumnWithTypeConverter<CrossfadeMode, String>
      crossfadeMode = GeneratedColumn<String>(
              'crossfade_mode', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<CrossfadeMode>(
              $PlaybackSettingsTableTable.$convertercrossfadeMode);
  static const VerificationMeta _crossfadeDurationMsMeta =
      const VerificationMeta('crossfadeDurationMs');
  @override
  late final GeneratedColumn<int> crossfadeDurationMs = GeneratedColumn<int>(
      'crossfade_duration_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _speedHundredthsMeta =
      const VerificationMeta('speedHundredths');
  @override
  late final GeneratedColumn<int> speedHundredths = GeneratedColumn<int>(
      'speed_hundredths', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _pitchCorrectionEnabledMeta =
      const VerificationMeta('pitchCorrectionEnabled');
  @override
  late final GeneratedColumn<bool> pitchCorrectionEnabled =
      GeneratedColumn<bool>('pitch_correction_enabled', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: true,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("pitch_correction_enabled" IN (0, 1))'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        crossfadeMode,
        crossfadeDurationMs,
        speedHundredths,
        pitchCorrectionEnabled
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playback_settings_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<PlaybackSettingsRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('crossfade_duration_ms')) {
      context.handle(
          _crossfadeDurationMsMeta,
          crossfadeDurationMs.isAcceptableOrUnknown(
              data['crossfade_duration_ms']!, _crossfadeDurationMsMeta));
    } else if (isInserting) {
      context.missing(_crossfadeDurationMsMeta);
    }
    if (data.containsKey('speed_hundredths')) {
      context.handle(
          _speedHundredthsMeta,
          speedHundredths.isAcceptableOrUnknown(
              data['speed_hundredths']!, _speedHundredthsMeta));
    } else if (isInserting) {
      context.missing(_speedHundredthsMeta);
    }
    if (data.containsKey('pitch_correction_enabled')) {
      context.handle(
          _pitchCorrectionEnabledMeta,
          pitchCorrectionEnabled.isAcceptableOrUnknown(
              data['pitch_correction_enabled']!, _pitchCorrectionEnabledMeta));
    } else if (isInserting) {
      context.missing(_pitchCorrectionEnabledMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaybackSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaybackSettingsRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      crossfadeMode: $PlaybackSettingsTableTable.$convertercrossfadeMode
          .fromSql(attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}crossfade_mode'])!),
      crossfadeDurationMs: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}crossfade_duration_ms'])!,
      speedHundredths: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}speed_hundredths'])!,
      pitchCorrectionEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}pitch_correction_enabled'])!,
    );
  }

  @override
  $PlaybackSettingsTableTable createAlias(String alias) {
    return $PlaybackSettingsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<CrossfadeMode, String> $convertercrossfadeMode =
      const CrossfadeModeConverter();
}

class PlaybackSettingsRow extends DataClass
    implements Insertable<PlaybackSettingsRow> {
  /// Always 0. Not a real identity — just the row-selector that makes
  /// "there's only ever one settings row" an enforceable invariant
  /// ([primaryKey]) instead of a convention the repository has to
  /// remember to honor by itself.
  final int id;
  final CrossfadeMode crossfadeMode;
  final int crossfadeDurationMs;

  /// Mirrors [PlaybackSpeed.speedHundredths] exactly (100 == 1.0x) —
  /// see that entity's docstring on why speed is stored as int
  /// hundredths rather than a raw double, to avoid tolerance-based
  /// equality on floating point.
  final int speedHundredths;
  final bool pitchCorrectionEnabled;
  const PlaybackSettingsRow(
      {required this.id,
      required this.crossfadeMode,
      required this.crossfadeDurationMs,
      required this.speedHundredths,
      required this.pitchCorrectionEnabled});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['crossfade_mode'] = Variable<String>($PlaybackSettingsTableTable
          .$convertercrossfadeMode
          .toSql(crossfadeMode));
    }
    map['crossfade_duration_ms'] = Variable<int>(crossfadeDurationMs);
    map['speed_hundredths'] = Variable<int>(speedHundredths);
    map['pitch_correction_enabled'] = Variable<bool>(pitchCorrectionEnabled);
    return map;
  }

  PlaybackSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return PlaybackSettingsTableCompanion(
      id: Value(id),
      crossfadeMode: Value(crossfadeMode),
      crossfadeDurationMs: Value(crossfadeDurationMs),
      speedHundredths: Value(speedHundredths),
      pitchCorrectionEnabled: Value(pitchCorrectionEnabled),
    );
  }

  factory PlaybackSettingsRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaybackSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      crossfadeMode: serializer.fromJson<CrossfadeMode>(json['crossfadeMode']),
      crossfadeDurationMs:
          serializer.fromJson<int>(json['crossfadeDurationMs']),
      speedHundredths: serializer.fromJson<int>(json['speedHundredths']),
      pitchCorrectionEnabled:
          serializer.fromJson<bool>(json['pitchCorrectionEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'crossfadeMode': serializer.toJson<CrossfadeMode>(crossfadeMode),
      'crossfadeDurationMs': serializer.toJson<int>(crossfadeDurationMs),
      'speedHundredths': serializer.toJson<int>(speedHundredths),
      'pitchCorrectionEnabled': serializer.toJson<bool>(pitchCorrectionEnabled),
    };
  }

  PlaybackSettingsRow copyWith(
          {int? id,
          CrossfadeMode? crossfadeMode,
          int? crossfadeDurationMs,
          int? speedHundredths,
          bool? pitchCorrectionEnabled}) =>
      PlaybackSettingsRow(
        id: id ?? this.id,
        crossfadeMode: crossfadeMode ?? this.crossfadeMode,
        crossfadeDurationMs: crossfadeDurationMs ?? this.crossfadeDurationMs,
        speedHundredths: speedHundredths ?? this.speedHundredths,
        pitchCorrectionEnabled:
            pitchCorrectionEnabled ?? this.pitchCorrectionEnabled,
      );
  PlaybackSettingsRow copyWithCompanion(PlaybackSettingsTableCompanion data) {
    return PlaybackSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      crossfadeMode: data.crossfadeMode.present
          ? data.crossfadeMode.value
          : this.crossfadeMode,
      crossfadeDurationMs: data.crossfadeDurationMs.present
          ? data.crossfadeDurationMs.value
          : this.crossfadeDurationMs,
      speedHundredths: data.speedHundredths.present
          ? data.speedHundredths.value
          : this.speedHundredths,
      pitchCorrectionEnabled: data.pitchCorrectionEnabled.present
          ? data.pitchCorrectionEnabled.value
          : this.pitchCorrectionEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackSettingsRow(')
          ..write('id: $id, ')
          ..write('crossfadeMode: $crossfadeMode, ')
          ..write('crossfadeDurationMs: $crossfadeDurationMs, ')
          ..write('speedHundredths: $speedHundredths, ')
          ..write('pitchCorrectionEnabled: $pitchCorrectionEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, crossfadeMode, crossfadeDurationMs,
      speedHundredths, pitchCorrectionEnabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackSettingsRow &&
          other.id == this.id &&
          other.crossfadeMode == this.crossfadeMode &&
          other.crossfadeDurationMs == this.crossfadeDurationMs &&
          other.speedHundredths == this.speedHundredths &&
          other.pitchCorrectionEnabled == this.pitchCorrectionEnabled);
}

class PlaybackSettingsTableCompanion
    extends UpdateCompanion<PlaybackSettingsRow> {
  final Value<int> id;
  final Value<CrossfadeMode> crossfadeMode;
  final Value<int> crossfadeDurationMs;
  final Value<int> speedHundredths;
  final Value<bool> pitchCorrectionEnabled;
  const PlaybackSettingsTableCompanion({
    this.id = const Value.absent(),
    this.crossfadeMode = const Value.absent(),
    this.crossfadeDurationMs = const Value.absent(),
    this.speedHundredths = const Value.absent(),
    this.pitchCorrectionEnabled = const Value.absent(),
  });
  PlaybackSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    required CrossfadeMode crossfadeMode,
    required int crossfadeDurationMs,
    required int speedHundredths,
    required bool pitchCorrectionEnabled,
  })  : crossfadeMode = Value(crossfadeMode),
        crossfadeDurationMs = Value(crossfadeDurationMs),
        speedHundredths = Value(speedHundredths),
        pitchCorrectionEnabled = Value(pitchCorrectionEnabled);
  static Insertable<PlaybackSettingsRow> custom({
    Expression<int>? id,
    Expression<String>? crossfadeMode,
    Expression<int>? crossfadeDurationMs,
    Expression<int>? speedHundredths,
    Expression<bool>? pitchCorrectionEnabled,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (crossfadeMode != null) 'crossfade_mode': crossfadeMode,
      if (crossfadeDurationMs != null)
        'crossfade_duration_ms': crossfadeDurationMs,
      if (speedHundredths != null) 'speed_hundredths': speedHundredths,
      if (pitchCorrectionEnabled != null)
        'pitch_correction_enabled': pitchCorrectionEnabled,
    });
  }

  PlaybackSettingsTableCompanion copyWith(
      {Value<int>? id,
      Value<CrossfadeMode>? crossfadeMode,
      Value<int>? crossfadeDurationMs,
      Value<int>? speedHundredths,
      Value<bool>? pitchCorrectionEnabled}) {
    return PlaybackSettingsTableCompanion(
      id: id ?? this.id,
      crossfadeMode: crossfadeMode ?? this.crossfadeMode,
      crossfadeDurationMs: crossfadeDurationMs ?? this.crossfadeDurationMs,
      speedHundredths: speedHundredths ?? this.speedHundredths,
      pitchCorrectionEnabled:
          pitchCorrectionEnabled ?? this.pitchCorrectionEnabled,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (crossfadeMode.present) {
      map['crossfade_mode'] = Variable<String>($PlaybackSettingsTableTable
          .$convertercrossfadeMode
          .toSql(crossfadeMode.value));
    }
    if (crossfadeDurationMs.present) {
      map['crossfade_duration_ms'] = Variable<int>(crossfadeDurationMs.value);
    }
    if (speedHundredths.present) {
      map['speed_hundredths'] = Variable<int>(speedHundredths.value);
    }
    if (pitchCorrectionEnabled.present) {
      map['pitch_correction_enabled'] =
          Variable<bool>(pitchCorrectionEnabled.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('crossfadeMode: $crossfadeMode, ')
          ..write('crossfadeDurationMs: $crossfadeDurationMs, ')
          ..write('speedHundredths: $speedHundredths, ')
          ..write('pitchCorrectionEnabled: $pitchCorrectionEnabled')
          ..write(')'))
        .toString();
  }
}

class $ActiveSessionTableTable extends ActiveSessionTable
    with TableInfo<$ActiveSessionTableTable, ActiveSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActiveSessionTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _activeQueueIdMeta =
      const VerificationMeta('activeQueueId');
  @override
  late final GeneratedColumn<String> activeQueueId = GeneratedColumn<String>(
      'active_queue_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _positionMsMeta =
      const VerificationMeta('positionMs');
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
      'position_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, activeQueueId, positionMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'active_session_table';
  @override
  VerificationContext validateIntegrity(Insertable<ActiveSessionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('active_queue_id')) {
      context.handle(
          _activeQueueIdMeta,
          activeQueueId.isAcceptableOrUnknown(
              data['active_queue_id']!, _activeQueueIdMeta));
    } else if (isInserting) {
      context.missing(_activeQueueIdMeta);
    }
    if (data.containsKey('position_ms')) {
      context.handle(
          _positionMsMeta,
          positionMs.isAcceptableOrUnknown(
              data['position_ms']!, _positionMsMeta));
    } else if (isInserting) {
      context.missing(_positionMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActiveSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActiveSessionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      activeQueueId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}active_queue_id'])!,
      positionMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position_ms'])!,
    );
  }

  @override
  $ActiveSessionTableTable createAlias(String alias) {
    return $ActiveSessionTableTable(attachedDatabase, alias);
  }
}

class ActiveSessionRow extends DataClass
    implements Insertable<ActiveSessionRow> {
  final int id;
  final String activeQueueId;
  final int positionMs;
  const ActiveSessionRow(
      {required this.id,
      required this.activeQueueId,
      required this.positionMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['active_queue_id'] = Variable<String>(activeQueueId);
    map['position_ms'] = Variable<int>(positionMs);
    return map;
  }

  ActiveSessionTableCompanion toCompanion(bool nullToAbsent) {
    return ActiveSessionTableCompanion(
      id: Value(id),
      activeQueueId: Value(activeQueueId),
      positionMs: Value(positionMs),
    );
  }

  factory ActiveSessionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActiveSessionRow(
      id: serializer.fromJson<int>(json['id']),
      activeQueueId: serializer.fromJson<String>(json['activeQueueId']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'activeQueueId': serializer.toJson<String>(activeQueueId),
      'positionMs': serializer.toJson<int>(positionMs),
    };
  }

  ActiveSessionRow copyWith(
          {int? id, String? activeQueueId, int? positionMs}) =>
      ActiveSessionRow(
        id: id ?? this.id,
        activeQueueId: activeQueueId ?? this.activeQueueId,
        positionMs: positionMs ?? this.positionMs,
      );
  ActiveSessionRow copyWithCompanion(ActiveSessionTableCompanion data) {
    return ActiveSessionRow(
      id: data.id.present ? data.id.value : this.id,
      activeQueueId: data.activeQueueId.present
          ? data.activeQueueId.value
          : this.activeQueueId,
      positionMs:
          data.positionMs.present ? data.positionMs.value : this.positionMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActiveSessionRow(')
          ..write('id: $id, ')
          ..write('activeQueueId: $activeQueueId, ')
          ..write('positionMs: $positionMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, activeQueueId, positionMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActiveSessionRow &&
          other.id == this.id &&
          other.activeQueueId == this.activeQueueId &&
          other.positionMs == this.positionMs);
}

class ActiveSessionTableCompanion extends UpdateCompanion<ActiveSessionRow> {
  final Value<int> id;
  final Value<String> activeQueueId;
  final Value<int> positionMs;
  const ActiveSessionTableCompanion({
    this.id = const Value.absent(),
    this.activeQueueId = const Value.absent(),
    this.positionMs = const Value.absent(),
  });
  ActiveSessionTableCompanion.insert({
    this.id = const Value.absent(),
    required String activeQueueId,
    required int positionMs,
  })  : activeQueueId = Value(activeQueueId),
        positionMs = Value(positionMs);
  static Insertable<ActiveSessionRow> custom({
    Expression<int>? id,
    Expression<String>? activeQueueId,
    Expression<int>? positionMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activeQueueId != null) 'active_queue_id': activeQueueId,
      if (positionMs != null) 'position_ms': positionMs,
    });
  }

  ActiveSessionTableCompanion copyWith(
      {Value<int>? id, Value<String>? activeQueueId, Value<int>? positionMs}) {
    return ActiveSessionTableCompanion(
      id: id ?? this.id,
      activeQueueId: activeQueueId ?? this.activeQueueId,
      positionMs: positionMs ?? this.positionMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (activeQueueId.present) {
      map['active_queue_id'] = Variable<String>(activeQueueId.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActiveSessionTableCompanion(')
          ..write('id: $id, ')
          ..write('activeQueueId: $activeQueueId, ')
          ..write('positionMs: $positionMs')
          ..write(')'))
        .toString();
  }
}

class $PlaylistsTable extends Playlists
    with TableInfo<$PlaylistsTable, PlaylistRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateCreatedUtcMsMeta =
      const VerificationMeta('dateCreatedUtcMs');
  @override
  late final GeneratedColumn<int> dateCreatedUtcMs = GeneratedColumn<int>(
      'date_created_utc_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, dateCreatedUtcMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(Insertable<PlaylistRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('date_created_utc_ms')) {
      context.handle(
          _dateCreatedUtcMsMeta,
          dateCreatedUtcMs.isAcceptableOrUnknown(
              data['date_created_utc_ms']!, _dateCreatedUtcMsMeta));
    } else if (isInserting) {
      context.missing(_dateCreatedUtcMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaylistRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      dateCreatedUtcMs: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}date_created_utc_ms'])!,
    );
  }

  @override
  $PlaylistsTable createAlias(String alias) {
    return $PlaylistsTable(attachedDatabase, alias);
  }
}

class PlaylistRow extends DataClass implements Insertable<PlaylistRow> {
  final String id;
  final String name;
  final int dateCreatedUtcMs;
  const PlaylistRow(
      {required this.id, required this.name, required this.dateCreatedUtcMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['date_created_utc_ms'] = Variable<int>(dateCreatedUtcMs);
    return map;
  }

  PlaylistsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistsCompanion(
      id: Value(id),
      name: Value(name),
      dateCreatedUtcMs: Value(dateCreatedUtcMs),
    );
  }

  factory PlaylistRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      dateCreatedUtcMs: serializer.fromJson<int>(json['dateCreatedUtcMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'dateCreatedUtcMs': serializer.toJson<int>(dateCreatedUtcMs),
    };
  }

  PlaylistRow copyWith({String? id, String? name, int? dateCreatedUtcMs}) =>
      PlaylistRow(
        id: id ?? this.id,
        name: name ?? this.name,
        dateCreatedUtcMs: dateCreatedUtcMs ?? this.dateCreatedUtcMs,
      );
  PlaylistRow copyWithCompanion(PlaylistsCompanion data) {
    return PlaylistRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      dateCreatedUtcMs: data.dateCreatedUtcMs.present
          ? data.dateCreatedUtcMs.value
          : this.dateCreatedUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('dateCreatedUtcMs: $dateCreatedUtcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, dateCreatedUtcMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.dateCreatedUtcMs == this.dateCreatedUtcMs);
}

class PlaylistsCompanion extends UpdateCompanion<PlaylistRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> dateCreatedUtcMs;
  final Value<int> rowid;
  const PlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.dateCreatedUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistsCompanion.insert({
    required String id,
    required String name,
    required int dateCreatedUtcMs,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        dateCreatedUtcMs = Value(dateCreatedUtcMs);
  static Insertable<PlaylistRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? dateCreatedUtcMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (dateCreatedUtcMs != null) 'date_created_utc_ms': dateCreatedUtcMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<int>? dateCreatedUtcMs,
      Value<int>? rowid}) {
    return PlaylistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      dateCreatedUtcMs: dateCreatedUtcMs ?? this.dateCreatedUtcMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dateCreatedUtcMs.present) {
      map['date_created_utc_ms'] = Variable<int>(dateCreatedUtcMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('dateCreatedUtcMs: $dateCreatedUtcMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistSongsTable extends PlaylistSongs
    with TableInfo<$PlaylistSongsTable, PlaylistSongRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistSongsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playlistIdMeta =
      const VerificationMeta('playlistId');
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
      'playlist_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES playlists (id)'));
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<String> songId = GeneratedColumn<String>(
      'song_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES songs (id)'));
  @override
  List<GeneratedColumn> get $columns => [playlistId, position, songId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_songs';
  @override
  VerificationContext validateIntegrity(Insertable<PlaylistSongRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('playlist_id')) {
      context.handle(
          _playlistIdMeta,
          playlistId.isAcceptableOrUnknown(
              data['playlist_id']!, _playlistIdMeta));
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('song_id')) {
      context.handle(_songIdMeta,
          songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta));
    } else if (isInserting) {
      context.missing(_songIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playlistId, position};
  @override
  PlaylistSongRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistSongRow(
      playlistId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}playlist_id'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      songId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}song_id'])!,
    );
  }

  @override
  $PlaylistSongsTable createAlias(String alias) {
    return $PlaylistSongsTable(attachedDatabase, alias);
  }
}

class PlaylistSongRow extends DataClass implements Insertable<PlaylistSongRow> {
  final String playlistId;
  final int position;
  final String songId;
  const PlaylistSongRow(
      {required this.playlistId, required this.position, required this.songId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['playlist_id'] = Variable<String>(playlistId);
    map['position'] = Variable<int>(position);
    map['song_id'] = Variable<String>(songId);
    return map;
  }

  PlaylistSongsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistSongsCompanion(
      playlistId: Value(playlistId),
      position: Value(position),
      songId: Value(songId),
    );
  }

  factory PlaylistSongRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistSongRow(
      playlistId: serializer.fromJson<String>(json['playlistId']),
      position: serializer.fromJson<int>(json['position']),
      songId: serializer.fromJson<String>(json['songId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playlistId': serializer.toJson<String>(playlistId),
      'position': serializer.toJson<int>(position),
      'songId': serializer.toJson<String>(songId),
    };
  }

  PlaylistSongRow copyWith(
          {String? playlistId, int? position, String? songId}) =>
      PlaylistSongRow(
        playlistId: playlistId ?? this.playlistId,
        position: position ?? this.position,
        songId: songId ?? this.songId,
      );
  PlaylistSongRow copyWithCompanion(PlaylistSongsCompanion data) {
    return PlaylistSongRow(
      playlistId:
          data.playlistId.present ? data.playlistId.value : this.playlistId,
      position: data.position.present ? data.position.value : this.position,
      songId: data.songId.present ? data.songId.value : this.songId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistSongRow(')
          ..write('playlistId: $playlistId, ')
          ..write('position: $position, ')
          ..write('songId: $songId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playlistId, position, songId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistSongRow &&
          other.playlistId == this.playlistId &&
          other.position == this.position &&
          other.songId == this.songId);
}

class PlaylistSongsCompanion extends UpdateCompanion<PlaylistSongRow> {
  final Value<String> playlistId;
  final Value<int> position;
  final Value<String> songId;
  final Value<int> rowid;
  const PlaylistSongsCompanion({
    this.playlistId = const Value.absent(),
    this.position = const Value.absent(),
    this.songId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistSongsCompanion.insert({
    required String playlistId,
    required int position,
    required String songId,
    this.rowid = const Value.absent(),
  })  : playlistId = Value(playlistId),
        position = Value(position),
        songId = Value(songId);
  static Insertable<PlaylistSongRow> custom({
    Expression<String>? playlistId,
    Expression<int>? position,
    Expression<String>? songId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playlistId != null) 'playlist_id': playlistId,
      if (position != null) 'position': position,
      if (songId != null) 'song_id': songId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistSongsCompanion copyWith(
      {Value<String>? playlistId,
      Value<int>? position,
      Value<String>? songId,
      Value<int>? rowid}) {
    return PlaylistSongsCompanion(
      playlistId: playlistId ?? this.playlistId,
      position: position ?? this.position,
      songId: songId ?? this.songId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (songId.present) {
      map['song_id'] = Variable<String>(songId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistSongsCompanion(')
          ..write('playlistId: $playlistId, ')
          ..write('position: $position, ')
          ..write('songId: $songId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaybackHistoryTable extends PlaybackHistory
    with TableInfo<$PlaybackHistoryTable, PlaybackHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaybackHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<String> songId = GeneratedColumn<String>(
      'song_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES songs (id)'));
  static const VerificationMeta _timestampUtcMsMeta =
      const VerificationMeta('timestampUtcMs');
  @override
  late final GeneratedColumn<int> timestampUtcMs = GeneratedColumn<int>(
      'timestamp_utc_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, songId, timestampUtcMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playback_history';
  @override
  VerificationContext validateIntegrity(Insertable<PlaybackHistoryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('song_id')) {
      context.handle(_songIdMeta,
          songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta));
    } else if (isInserting) {
      context.missing(_songIdMeta);
    }
    if (data.containsKey('timestamp_utc_ms')) {
      context.handle(
          _timestampUtcMsMeta,
          timestampUtcMs.isAcceptableOrUnknown(
              data['timestamp_utc_ms']!, _timestampUtcMsMeta));
    } else if (isInserting) {
      context.missing(_timestampUtcMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaybackHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaybackHistoryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      songId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}song_id'])!,
      timestampUtcMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp_utc_ms'])!,
    );
  }

  @override
  $PlaybackHistoryTable createAlias(String alias) {
    return $PlaybackHistoryTable(attachedDatabase, alias);
  }
}

class PlaybackHistoryRow extends DataClass
    implements Insertable<PlaybackHistoryRow> {
  final int id;
  final String songId;

  /// When the song was played (Epoch milliseconds, UTC).
  final int timestampUtcMs;
  const PlaybackHistoryRow(
      {required this.id, required this.songId, required this.timestampUtcMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['song_id'] = Variable<String>(songId);
    map['timestamp_utc_ms'] = Variable<int>(timestampUtcMs);
    return map;
  }

  PlaybackHistoryCompanion toCompanion(bool nullToAbsent) {
    return PlaybackHistoryCompanion(
      id: Value(id),
      songId: Value(songId),
      timestampUtcMs: Value(timestampUtcMs),
    );
  }

  factory PlaybackHistoryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaybackHistoryRow(
      id: serializer.fromJson<int>(json['id']),
      songId: serializer.fromJson<String>(json['songId']),
      timestampUtcMs: serializer.fromJson<int>(json['timestampUtcMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'songId': serializer.toJson<String>(songId),
      'timestampUtcMs': serializer.toJson<int>(timestampUtcMs),
    };
  }

  PlaybackHistoryRow copyWith({int? id, String? songId, int? timestampUtcMs}) =>
      PlaybackHistoryRow(
        id: id ?? this.id,
        songId: songId ?? this.songId,
        timestampUtcMs: timestampUtcMs ?? this.timestampUtcMs,
      );
  PlaybackHistoryRow copyWithCompanion(PlaybackHistoryCompanion data) {
    return PlaybackHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      songId: data.songId.present ? data.songId.value : this.songId,
      timestampUtcMs: data.timestampUtcMs.present
          ? data.timestampUtcMs.value
          : this.timestampUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackHistoryRow(')
          ..write('id: $id, ')
          ..write('songId: $songId, ')
          ..write('timestampUtcMs: $timestampUtcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, songId, timestampUtcMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaybackHistoryRow &&
          other.id == this.id &&
          other.songId == this.songId &&
          other.timestampUtcMs == this.timestampUtcMs);
}

class PlaybackHistoryCompanion extends UpdateCompanion<PlaybackHistoryRow> {
  final Value<int> id;
  final Value<String> songId;
  final Value<int> timestampUtcMs;
  const PlaybackHistoryCompanion({
    this.id = const Value.absent(),
    this.songId = const Value.absent(),
    this.timestampUtcMs = const Value.absent(),
  });
  PlaybackHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String songId,
    required int timestampUtcMs,
  })  : songId = Value(songId),
        timestampUtcMs = Value(timestampUtcMs);
  static Insertable<PlaybackHistoryRow> custom({
    Expression<int>? id,
    Expression<String>? songId,
    Expression<int>? timestampUtcMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (songId != null) 'song_id': songId,
      if (timestampUtcMs != null) 'timestamp_utc_ms': timestampUtcMs,
    });
  }

  PlaybackHistoryCompanion copyWith(
      {Value<int>? id, Value<String>? songId, Value<int>? timestampUtcMs}) {
    return PlaybackHistoryCompanion(
      id: id ?? this.id,
      songId: songId ?? this.songId,
      timestampUtcMs: timestampUtcMs ?? this.timestampUtcMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (songId.present) {
      map['song_id'] = Variable<String>(songId.value);
    }
    if (timestampUtcMs.present) {
      map['timestamp_utc_ms'] = Variable<int>(timestampUtcMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaybackHistoryCompanion(')
          ..write('id: $id, ')
          ..write('songId: $songId, ')
          ..write('timestampUtcMs: $timestampUtcMs')
          ..write(')'))
        .toString();
  }
}

class $ItemInteractionsTable extends ItemInteractions
    with TableInfo<$ItemInteractionsTable, ItemInteractionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemInteractionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
      'item_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemTypeMeta =
      const VerificationMeta('itemType');
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
      'item_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _interactionMeta =
      const VerificationMeta('interaction');
  @override
  late final GeneratedColumn<int> interaction = GeneratedColumn<int>(
      'interaction', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _timestampUtcMsMeta =
      const VerificationMeta('timestampUtcMs');
  @override
  late final GeneratedColumn<int> timestampUtcMs = GeneratedColumn<int>(
      'timestamp_utc_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [itemId, itemType, interaction, timestampUtcMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'item_interactions';
  @override
  VerificationContext validateIntegrity(Insertable<ItemInteractionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('item_type')) {
      context.handle(_itemTypeMeta,
          itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta));
    } else if (isInserting) {
      context.missing(_itemTypeMeta);
    }
    if (data.containsKey('interaction')) {
      context.handle(
          _interactionMeta,
          interaction.isAcceptableOrUnknown(
              data['interaction']!, _interactionMeta));
    } else if (isInserting) {
      context.missing(_interactionMeta);
    }
    if (data.containsKey('timestamp_utc_ms')) {
      context.handle(
          _timestampUtcMsMeta,
          timestampUtcMs.isAcceptableOrUnknown(
              data['timestamp_utc_ms']!, _timestampUtcMsMeta));
    } else if (isInserting) {
      context.missing(_timestampUtcMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {itemId, itemType};
  @override
  ItemInteractionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ItemInteractionRow(
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_id'])!,
      itemType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_type'])!,
      interaction: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}interaction'])!,
      timestampUtcMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}timestamp_utc_ms'])!,
    );
  }

  @override
  $ItemInteractionsTable createAlias(String alias) {
    return $ItemInteractionsTable(attachedDatabase, alias);
  }
}

class ItemInteractionRow extends DataClass
    implements Insertable<ItemInteractionRow> {
  /// The SongId, PlaylistId, Album name, or Artist name.
  final String itemId;

  /// 'song', 'album', 'artist', or 'playlist'.
  final String itemType;

  /// 1 for Like (Heart), -1 for Dislike (Heart-break).
  /// If a user removes their like, the row is deleted entirely.
  final int interaction;
  final int timestampUtcMs;
  const ItemInteractionRow(
      {required this.itemId,
      required this.itemType,
      required this.interaction,
      required this.timestampUtcMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['item_id'] = Variable<String>(itemId);
    map['item_type'] = Variable<String>(itemType);
    map['interaction'] = Variable<int>(interaction);
    map['timestamp_utc_ms'] = Variable<int>(timestampUtcMs);
    return map;
  }

  ItemInteractionsCompanion toCompanion(bool nullToAbsent) {
    return ItemInteractionsCompanion(
      itemId: Value(itemId),
      itemType: Value(itemType),
      interaction: Value(interaction),
      timestampUtcMs: Value(timestampUtcMs),
    );
  }

  factory ItemInteractionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ItemInteractionRow(
      itemId: serializer.fromJson<String>(json['itemId']),
      itemType: serializer.fromJson<String>(json['itemType']),
      interaction: serializer.fromJson<int>(json['interaction']),
      timestampUtcMs: serializer.fromJson<int>(json['timestampUtcMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'itemId': serializer.toJson<String>(itemId),
      'itemType': serializer.toJson<String>(itemType),
      'interaction': serializer.toJson<int>(interaction),
      'timestampUtcMs': serializer.toJson<int>(timestampUtcMs),
    };
  }

  ItemInteractionRow copyWith(
          {String? itemId,
          String? itemType,
          int? interaction,
          int? timestampUtcMs}) =>
      ItemInteractionRow(
        itemId: itemId ?? this.itemId,
        itemType: itemType ?? this.itemType,
        interaction: interaction ?? this.interaction,
        timestampUtcMs: timestampUtcMs ?? this.timestampUtcMs,
      );
  ItemInteractionRow copyWithCompanion(ItemInteractionsCompanion data) {
    return ItemInteractionRow(
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      interaction:
          data.interaction.present ? data.interaction.value : this.interaction,
      timestampUtcMs: data.timestampUtcMs.present
          ? data.timestampUtcMs.value
          : this.timestampUtcMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ItemInteractionRow(')
          ..write('itemId: $itemId, ')
          ..write('itemType: $itemType, ')
          ..write('interaction: $interaction, ')
          ..write('timestampUtcMs: $timestampUtcMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(itemId, itemType, interaction, timestampUtcMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ItemInteractionRow &&
          other.itemId == this.itemId &&
          other.itemType == this.itemType &&
          other.interaction == this.interaction &&
          other.timestampUtcMs == this.timestampUtcMs);
}

class ItemInteractionsCompanion extends UpdateCompanion<ItemInteractionRow> {
  final Value<String> itemId;
  final Value<String> itemType;
  final Value<int> interaction;
  final Value<int> timestampUtcMs;
  final Value<int> rowid;
  const ItemInteractionsCompanion({
    this.itemId = const Value.absent(),
    this.itemType = const Value.absent(),
    this.interaction = const Value.absent(),
    this.timestampUtcMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemInteractionsCompanion.insert({
    required String itemId,
    required String itemType,
    required int interaction,
    required int timestampUtcMs,
    this.rowid = const Value.absent(),
  })  : itemId = Value(itemId),
        itemType = Value(itemType),
        interaction = Value(interaction),
        timestampUtcMs = Value(timestampUtcMs);
  static Insertable<ItemInteractionRow> custom({
    Expression<String>? itemId,
    Expression<String>? itemType,
    Expression<int>? interaction,
    Expression<int>? timestampUtcMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (itemId != null) 'item_id': itemId,
      if (itemType != null) 'item_type': itemType,
      if (interaction != null) 'interaction': interaction,
      if (timestampUtcMs != null) 'timestamp_utc_ms': timestampUtcMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemInteractionsCompanion copyWith(
      {Value<String>? itemId,
      Value<String>? itemType,
      Value<int>? interaction,
      Value<int>? timestampUtcMs,
      Value<int>? rowid}) {
    return ItemInteractionsCompanion(
      itemId: itemId ?? this.itemId,
      itemType: itemType ?? this.itemType,
      interaction: interaction ?? this.interaction,
      timestampUtcMs: timestampUtcMs ?? this.timestampUtcMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (interaction.present) {
      map['interaction'] = Variable<int>(interaction.value);
    }
    if (timestampUtcMs.present) {
      map['timestamp_utc_ms'] = Variable<int>(timestampUtcMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemInteractionsCompanion(')
          ..write('itemId: $itemId, ')
          ..write('itemType: $itemType, ')
          ..write('interaction: $interaction, ')
          ..write('timestampUtcMs: $timestampUtcMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SongsTable songs = $SongsTable(this);
  late final $PlaybackQueuesTable playbackQueues = $PlaybackQueuesTable(this);
  late final $QueueSongsTable queueSongs = $QueueSongsTable(this);
  late final $PlaybackSettingsTableTable playbackSettingsTable =
      $PlaybackSettingsTableTable(this);
  late final $ActiveSessionTableTable activeSessionTable =
      $ActiveSessionTableTable(this);
  late final $PlaylistsTable playlists = $PlaylistsTable(this);
  late final $PlaylistSongsTable playlistSongs = $PlaylistSongsTable(this);
  late final $PlaybackHistoryTable playbackHistory =
      $PlaybackHistoryTable(this);
  late final $ItemInteractionsTable itemInteractions =
      $ItemInteractionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        songs,
        playbackQueues,
        queueSongs,
        playbackSettingsTable,
        activeSessionTable,
        playlists,
        playlistSongs,
        playbackHistory,
        itemInteractions
      ];
}

typedef $$SongsTableCreateCompanionBuilder = SongsCompanion Function({
  required String id,
  required String title,
  required String trackArtistId,
  Value<String?> albumArtistId,
  Value<String?> albumId,
  Value<int?> trackNumber,
  Value<int?> discNumber,
  required int durationMs,
  required String filePath,
  required AudioFormat format,
  required int fileSizeBytes,
  required List<String> genreNames,
  Value<int?> year,
  Value<String?> coverArtPath,
  Value<int> leadingSilenceMs,
  Value<int> trailingSilenceMs,
  Value<double?> replayGainTrackDb,
  Value<double?> replayGainAlbumDb,
  required int dateAddedUtcMs,
  Value<bool> isMissing,
  Value<int> rowid,
});
typedef $$SongsTableUpdateCompanionBuilder = SongsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> trackArtistId,
  Value<String?> albumArtistId,
  Value<String?> albumId,
  Value<int?> trackNumber,
  Value<int?> discNumber,
  Value<int> durationMs,
  Value<String> filePath,
  Value<AudioFormat> format,
  Value<int> fileSizeBytes,
  Value<List<String>> genreNames,
  Value<int?> year,
  Value<String?> coverArtPath,
  Value<int> leadingSilenceMs,
  Value<int> trailingSilenceMs,
  Value<double?> replayGainTrackDb,
  Value<double?> replayGainAlbumDb,
  Value<int> dateAddedUtcMs,
  Value<bool> isMissing,
  Value<int> rowid,
});

final class $$SongsTableReferences
    extends BaseReferences<_$AppDatabase, $SongsTable, SongRow> {
  $$SongsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$QueueSongsTable, List<QueueSongRow>>
      _queueSongsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.queueSongs,
              aliasName: 'songs__id__queue_songs__song_id');

  $$QueueSongsTableProcessedTableManager get queueSongsRefs {
    final manager = $$QueueSongsTableTableManager($_db, $_db.queueSongs)
        .filter((f) => f.songId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_queueSongsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PlaylistSongsTable, List<PlaylistSongRow>>
      _playlistSongsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.playlistSongs,
              aliasName: 'songs__id__playlist_songs__song_id');

  $$PlaylistSongsTableProcessedTableManager get playlistSongsRefs {
    final manager = $$PlaylistSongsTableTableManager($_db, $_db.playlistSongs)
        .filter((f) => f.songId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_playlistSongsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$PlaybackHistoryTable, List<PlaybackHistoryRow>>
      _playbackHistoryRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.playbackHistory,
              aliasName: 'songs__id__playback_history__song_id');

  $$PlaybackHistoryTableProcessedTableManager get playbackHistoryRefs {
    final manager =
        $$PlaybackHistoryTableTableManager($_db, $_db.playbackHistory)
            .filter((f) => f.songId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_playbackHistoryRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SongsTableFilterComposer extends Composer<_$AppDatabase, $SongsTable> {
  $$SongsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get trackArtistId => $composableBuilder(
      column: $table.trackArtistId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get albumArtistId => $composableBuilder(
      column: $table.albumArtistId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get albumId => $composableBuilder(
      column: $table.albumId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get trackNumber => $composableBuilder(
      column: $table.trackNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get discNumber => $composableBuilder(
      column: $table.discNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<AudioFormat, AudioFormat, String> get format =>
      $composableBuilder(
          column: $table.format,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
      get genreNames => $composableBuilder(
          column: $table.genreNames,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverArtPath => $composableBuilder(
      column: $table.coverArtPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get leadingSilenceMs => $composableBuilder(
      column: $table.leadingSilenceMs,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get trailingSilenceMs => $composableBuilder(
      column: $table.trailingSilenceMs,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get replayGainTrackDb => $composableBuilder(
      column: $table.replayGainTrackDb,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get replayGainAlbumDb => $composableBuilder(
      column: $table.replayGainAlbumDb,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dateAddedUtcMs => $composableBuilder(
      column: $table.dateAddedUtcMs,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isMissing => $composableBuilder(
      column: $table.isMissing, builder: (column) => ColumnFilters(column));

  Expression<bool> queueSongsRefs(
      Expression<bool> Function($$QueueSongsTableFilterComposer f) f) {
    final $$QueueSongsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.queueSongs,
        getReferencedColumn: (t) => t.songId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QueueSongsTableFilterComposer(
              $db: $db,
              $table: $db.queueSongs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> playlistSongsRefs(
      Expression<bool> Function($$PlaylistSongsTableFilterComposer f) f) {
    final $$PlaylistSongsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.playlistSongs,
        getReferencedColumn: (t) => t.songId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistSongsTableFilterComposer(
              $db: $db,
              $table: $db.playlistSongs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> playbackHistoryRefs(
      Expression<bool> Function($$PlaybackHistoryTableFilterComposer f) f) {
    final $$PlaybackHistoryTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.playbackHistory,
        getReferencedColumn: (t) => t.songId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaybackHistoryTableFilterComposer(
              $db: $db,
              $table: $db.playbackHistory,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SongsTableOrderingComposer
    extends Composer<_$AppDatabase, $SongsTable> {
  $$SongsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get trackArtistId => $composableBuilder(
      column: $table.trackArtistId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get albumArtistId => $composableBuilder(
      column: $table.albumArtistId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get albumId => $composableBuilder(
      column: $table.albumId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get trackNumber => $composableBuilder(
      column: $table.trackNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get discNumber => $composableBuilder(
      column: $table.discNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get format => $composableBuilder(
      column: $table.format, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get genreNames => $composableBuilder(
      column: $table.genreNames, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get year => $composableBuilder(
      column: $table.year, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverArtPath => $composableBuilder(
      column: $table.coverArtPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get leadingSilenceMs => $composableBuilder(
      column: $table.leadingSilenceMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get trailingSilenceMs => $composableBuilder(
      column: $table.trailingSilenceMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get replayGainTrackDb => $composableBuilder(
      column: $table.replayGainTrackDb,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get replayGainAlbumDb => $composableBuilder(
      column: $table.replayGainAlbumDb,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dateAddedUtcMs => $composableBuilder(
      column: $table.dateAddedUtcMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isMissing => $composableBuilder(
      column: $table.isMissing, builder: (column) => ColumnOrderings(column));
}

class $$SongsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SongsTable> {
  $$SongsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get trackArtistId => $composableBuilder(
      column: $table.trackArtistId, builder: (column) => column);

  GeneratedColumn<String> get albumArtistId => $composableBuilder(
      column: $table.albumArtistId, builder: (column) => column);

  GeneratedColumn<String> get albumId =>
      $composableBuilder(column: $table.albumId, builder: (column) => column);

  GeneratedColumn<int> get trackNumber => $composableBuilder(
      column: $table.trackNumber, builder: (column) => column);

  GeneratedColumn<int> get discNumber => $composableBuilder(
      column: $table.discNumber, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AudioFormat, String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
      column: $table.fileSizeBytes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get genreNames =>
      $composableBuilder(
          column: $table.genreNames, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get coverArtPath => $composableBuilder(
      column: $table.coverArtPath, builder: (column) => column);

  GeneratedColumn<int> get leadingSilenceMs => $composableBuilder(
      column: $table.leadingSilenceMs, builder: (column) => column);

  GeneratedColumn<int> get trailingSilenceMs => $composableBuilder(
      column: $table.trailingSilenceMs, builder: (column) => column);

  GeneratedColumn<double> get replayGainTrackDb => $composableBuilder(
      column: $table.replayGainTrackDb, builder: (column) => column);

  GeneratedColumn<double> get replayGainAlbumDb => $composableBuilder(
      column: $table.replayGainAlbumDb, builder: (column) => column);

  GeneratedColumn<int> get dateAddedUtcMs => $composableBuilder(
      column: $table.dateAddedUtcMs, builder: (column) => column);

  GeneratedColumn<bool> get isMissing =>
      $composableBuilder(column: $table.isMissing, builder: (column) => column);

  Expression<T> queueSongsRefs<T extends Object>(
      Expression<T> Function($$QueueSongsTableAnnotationComposer a) f) {
    final $$QueueSongsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.queueSongs,
        getReferencedColumn: (t) => t.songId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QueueSongsTableAnnotationComposer(
              $db: $db,
              $table: $db.queueSongs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> playlistSongsRefs<T extends Object>(
      Expression<T> Function($$PlaylistSongsTableAnnotationComposer a) f) {
    final $$PlaylistSongsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.playlistSongs,
        getReferencedColumn: (t) => t.songId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistSongsTableAnnotationComposer(
              $db: $db,
              $table: $db.playlistSongs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> playbackHistoryRefs<T extends Object>(
      Expression<T> Function($$PlaybackHistoryTableAnnotationComposer a) f) {
    final $$PlaybackHistoryTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.playbackHistory,
        getReferencedColumn: (t) => t.songId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaybackHistoryTableAnnotationComposer(
              $db: $db,
              $table: $db.playbackHistory,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$SongsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SongsTable,
    SongRow,
    $$SongsTableFilterComposer,
    $$SongsTableOrderingComposer,
    $$SongsTableAnnotationComposer,
    $$SongsTableCreateCompanionBuilder,
    $$SongsTableUpdateCompanionBuilder,
    (SongRow, $$SongsTableReferences),
    SongRow,
    PrefetchHooks Function(
        {bool queueSongsRefs,
        bool playlistSongsRefs,
        bool playbackHistoryRefs})> {
  $$SongsTableTableManager(_$AppDatabase db, $SongsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SongsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SongsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SongsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> trackArtistId = const Value.absent(),
            Value<String?> albumArtistId = const Value.absent(),
            Value<String?> albumId = const Value.absent(),
            Value<int?> trackNumber = const Value.absent(),
            Value<int?> discNumber = const Value.absent(),
            Value<int> durationMs = const Value.absent(),
            Value<String> filePath = const Value.absent(),
            Value<AudioFormat> format = const Value.absent(),
            Value<int> fileSizeBytes = const Value.absent(),
            Value<List<String>> genreNames = const Value.absent(),
            Value<int?> year = const Value.absent(),
            Value<String?> coverArtPath = const Value.absent(),
            Value<int> leadingSilenceMs = const Value.absent(),
            Value<int> trailingSilenceMs = const Value.absent(),
            Value<double?> replayGainTrackDb = const Value.absent(),
            Value<double?> replayGainAlbumDb = const Value.absent(),
            Value<int> dateAddedUtcMs = const Value.absent(),
            Value<bool> isMissing = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SongsCompanion(
            id: id,
            title: title,
            trackArtistId: trackArtistId,
            albumArtistId: albumArtistId,
            albumId: albumId,
            trackNumber: trackNumber,
            discNumber: discNumber,
            durationMs: durationMs,
            filePath: filePath,
            format: format,
            fileSizeBytes: fileSizeBytes,
            genreNames: genreNames,
            year: year,
            coverArtPath: coverArtPath,
            leadingSilenceMs: leadingSilenceMs,
            trailingSilenceMs: trailingSilenceMs,
            replayGainTrackDb: replayGainTrackDb,
            replayGainAlbumDb: replayGainAlbumDb,
            dateAddedUtcMs: dateAddedUtcMs,
            isMissing: isMissing,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            required String trackArtistId,
            Value<String?> albumArtistId = const Value.absent(),
            Value<String?> albumId = const Value.absent(),
            Value<int?> trackNumber = const Value.absent(),
            Value<int?> discNumber = const Value.absent(),
            required int durationMs,
            required String filePath,
            required AudioFormat format,
            required int fileSizeBytes,
            required List<String> genreNames,
            Value<int?> year = const Value.absent(),
            Value<String?> coverArtPath = const Value.absent(),
            Value<int> leadingSilenceMs = const Value.absent(),
            Value<int> trailingSilenceMs = const Value.absent(),
            Value<double?> replayGainTrackDb = const Value.absent(),
            Value<double?> replayGainAlbumDb = const Value.absent(),
            required int dateAddedUtcMs,
            Value<bool> isMissing = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SongsCompanion.insert(
            id: id,
            title: title,
            trackArtistId: trackArtistId,
            albumArtistId: albumArtistId,
            albumId: albumId,
            trackNumber: trackNumber,
            discNumber: discNumber,
            durationMs: durationMs,
            filePath: filePath,
            format: format,
            fileSizeBytes: fileSizeBytes,
            genreNames: genreNames,
            year: year,
            coverArtPath: coverArtPath,
            leadingSilenceMs: leadingSilenceMs,
            trailingSilenceMs: trailingSilenceMs,
            replayGainTrackDb: replayGainTrackDb,
            replayGainAlbumDb: replayGainAlbumDb,
            dateAddedUtcMs: dateAddedUtcMs,
            isMissing: isMissing,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$SongsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {queueSongsRefs = false,
              playlistSongsRefs = false,
              playbackHistoryRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (queueSongsRefs) db.queueSongs,
                if (playlistSongsRefs) db.playlistSongs,
                if (playbackHistoryRefs) db.playbackHistory
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (queueSongsRefs)
                    await $_getPrefetchedData<SongRow, $SongsTable,
                            QueueSongRow>(
                        currentTable: table,
                        referencedTable:
                            $$SongsTableReferences._queueSongsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SongsTableReferences(db, table, p0)
                                .queueSongsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.songId == item.id),
                        typedResults: items),
                  if (playlistSongsRefs)
                    await $_getPrefetchedData<SongRow, $SongsTable,
                            PlaylistSongRow>(
                        currentTable: table,
                        referencedTable:
                            $$SongsTableReferences._playlistSongsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SongsTableReferences(db, table, p0)
                                .playlistSongsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.songId == item.id),
                        typedResults: items),
                  if (playbackHistoryRefs)
                    await $_getPrefetchedData<SongRow, $SongsTable,
                            PlaybackHistoryRow>(
                        currentTable: table,
                        referencedTable: $$SongsTableReferences
                            ._playbackHistoryRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SongsTableReferences(db, table, p0)
                                .playbackHistoryRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.songId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SongsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SongsTable,
    SongRow,
    $$SongsTableFilterComposer,
    $$SongsTableOrderingComposer,
    $$SongsTableAnnotationComposer,
    $$SongsTableCreateCompanionBuilder,
    $$SongsTableUpdateCompanionBuilder,
    (SongRow, $$SongsTableReferences),
    SongRow,
    PrefetchHooks Function(
        {bool queueSongsRefs,
        bool playlistSongsRefs,
        bool playbackHistoryRefs})>;
typedef $$PlaybackQueuesTableCreateCompanionBuilder = PlaybackQueuesCompanion
    Function({
  required String id,
  required int currentIndex,
  required RepeatMode repeatMode,
  required QueueSource source,
  Value<bool> shuffleEnabled,
  Value<int?> preShuffleCurrentIndex,
  Value<int> rowid,
});
typedef $$PlaybackQueuesTableUpdateCompanionBuilder = PlaybackQueuesCompanion
    Function({
  Value<String> id,
  Value<int> currentIndex,
  Value<RepeatMode> repeatMode,
  Value<QueueSource> source,
  Value<bool> shuffleEnabled,
  Value<int?> preShuffleCurrentIndex,
  Value<int> rowid,
});

final class $$PlaybackQueuesTableReferences extends BaseReferences<
    _$AppDatabase, $PlaybackQueuesTable, PlaybackQueueRow> {
  $$PlaybackQueuesTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$QueueSongsTable, List<QueueSongRow>>
      _queueSongsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.queueSongs,
              aliasName: 'playback_queues__id__queue_songs__queue_id');

  $$QueueSongsTableProcessedTableManager get queueSongsRefs {
    final manager = $$QueueSongsTableTableManager($_db, $_db.queueSongs)
        .filter((f) => f.queueId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_queueSongsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PlaybackQueuesTableFilterComposer
    extends Composer<_$AppDatabase, $PlaybackQueuesTable> {
  $$PlaybackQueuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get currentIndex => $composableBuilder(
      column: $table.currentIndex, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<RepeatMode, RepeatMode, String>
      get repeatMode => $composableBuilder(
          column: $table.repeatMode,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<QueueSource, QueueSource, String> get source =>
      $composableBuilder(
          column: $table.source,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get shuffleEnabled => $composableBuilder(
      column: $table.shuffleEnabled,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get preShuffleCurrentIndex => $composableBuilder(
      column: $table.preShuffleCurrentIndex,
      builder: (column) => ColumnFilters(column));

  Expression<bool> queueSongsRefs(
      Expression<bool> Function($$QueueSongsTableFilterComposer f) f) {
    final $$QueueSongsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.queueSongs,
        getReferencedColumn: (t) => t.queueId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QueueSongsTableFilterComposer(
              $db: $db,
              $table: $db.queueSongs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PlaybackQueuesTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaybackQueuesTable> {
  $$PlaybackQueuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get currentIndex => $composableBuilder(
      column: $table.currentIndex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repeatMode => $composableBuilder(
      column: $table.repeatMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get shuffleEnabled => $composableBuilder(
      column: $table.shuffleEnabled,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get preShuffleCurrentIndex => $composableBuilder(
      column: $table.preShuffleCurrentIndex,
      builder: (column) => ColumnOrderings(column));
}

class $$PlaybackQueuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaybackQueuesTable> {
  $$PlaybackQueuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get currentIndex => $composableBuilder(
      column: $table.currentIndex, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RepeatMode, String> get repeatMode =>
      $composableBuilder(
          column: $table.repeatMode, builder: (column) => column);

  GeneratedColumnWithTypeConverter<QueueSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<bool> get shuffleEnabled => $composableBuilder(
      column: $table.shuffleEnabled, builder: (column) => column);

  GeneratedColumn<int> get preShuffleCurrentIndex => $composableBuilder(
      column: $table.preShuffleCurrentIndex, builder: (column) => column);

  Expression<T> queueSongsRefs<T extends Object>(
      Expression<T> Function($$QueueSongsTableAnnotationComposer a) f) {
    final $$QueueSongsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.queueSongs,
        getReferencedColumn: (t) => t.queueId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QueueSongsTableAnnotationComposer(
              $db: $db,
              $table: $db.queueSongs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PlaybackQueuesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlaybackQueuesTable,
    PlaybackQueueRow,
    $$PlaybackQueuesTableFilterComposer,
    $$PlaybackQueuesTableOrderingComposer,
    $$PlaybackQueuesTableAnnotationComposer,
    $$PlaybackQueuesTableCreateCompanionBuilder,
    $$PlaybackQueuesTableUpdateCompanionBuilder,
    (PlaybackQueueRow, $$PlaybackQueuesTableReferences),
    PlaybackQueueRow,
    PrefetchHooks Function({bool queueSongsRefs})> {
  $$PlaybackQueuesTableTableManager(
      _$AppDatabase db, $PlaybackQueuesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaybackQueuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaybackQueuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaybackQueuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> currentIndex = const Value.absent(),
            Value<RepeatMode> repeatMode = const Value.absent(),
            Value<QueueSource> source = const Value.absent(),
            Value<bool> shuffleEnabled = const Value.absent(),
            Value<int?> preShuffleCurrentIndex = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlaybackQueuesCompanion(
            id: id,
            currentIndex: currentIndex,
            repeatMode: repeatMode,
            source: source,
            shuffleEnabled: shuffleEnabled,
            preShuffleCurrentIndex: preShuffleCurrentIndex,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int currentIndex,
            required RepeatMode repeatMode,
            required QueueSource source,
            Value<bool> shuffleEnabled = const Value.absent(),
            Value<int?> preShuffleCurrentIndex = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlaybackQueuesCompanion.insert(
            id: id,
            currentIndex: currentIndex,
            repeatMode: repeatMode,
            source: source,
            shuffleEnabled: shuffleEnabled,
            preShuffleCurrentIndex: preShuffleCurrentIndex,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PlaybackQueuesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({queueSongsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (queueSongsRefs) db.queueSongs],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (queueSongsRefs)
                    await $_getPrefetchedData<PlaybackQueueRow,
                            $PlaybackQueuesTable, QueueSongRow>(
                        currentTable: table,
                        referencedTable: $$PlaybackQueuesTableReferences
                            ._queueSongsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PlaybackQueuesTableReferences(db, table, p0)
                                .queueSongsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.queueId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PlaybackQueuesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlaybackQueuesTable,
    PlaybackQueueRow,
    $$PlaybackQueuesTableFilterComposer,
    $$PlaybackQueuesTableOrderingComposer,
    $$PlaybackQueuesTableAnnotationComposer,
    $$PlaybackQueuesTableCreateCompanionBuilder,
    $$PlaybackQueuesTableUpdateCompanionBuilder,
    (PlaybackQueueRow, $$PlaybackQueuesTableReferences),
    PlaybackQueueRow,
    PrefetchHooks Function({bool queueSongsRefs})>;
typedef $$QueueSongsTableCreateCompanionBuilder = QueueSongsCompanion Function({
  required String queueId,
  required String listKind,
  required int position,
  required String songId,
  Value<int> rowid,
});
typedef $$QueueSongsTableUpdateCompanionBuilder = QueueSongsCompanion Function({
  Value<String> queueId,
  Value<String> listKind,
  Value<int> position,
  Value<String> songId,
  Value<int> rowid,
});

final class $$QueueSongsTableReferences
    extends BaseReferences<_$AppDatabase, $QueueSongsTable, QueueSongRow> {
  $$QueueSongsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $PlaybackQueuesTable _queueIdTable(_$AppDatabase db) =>
      db.playbackQueues
          .createAlias('queue_songs__queue_id__playback_queues__id');

  $$PlaybackQueuesTableProcessedTableManager get queueId {
    final $_column = $_itemColumn<String>('queue_id')!;

    final manager = $$PlaybackQueuesTableTableManager($_db, $_db.playbackQueues)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_queueIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $SongsTable _songIdTable(_$AppDatabase db) =>
      db.songs.createAlias('queue_songs__song_id__songs__id');

  $$SongsTableProcessedTableManager get songId {
    final $_column = $_itemColumn<String>('song_id')!;

    final manager = $$SongsTableTableManager($_db, $_db.songs)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_songIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$QueueSongsTableFilterComposer
    extends Composer<_$AppDatabase, $QueueSongsTable> {
  $$QueueSongsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get listKind => $composableBuilder(
      column: $table.listKind, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  $$PlaybackQueuesTableFilterComposer get queueId {
    final $$PlaybackQueuesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.queueId,
        referencedTable: $db.playbackQueues,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaybackQueuesTableFilterComposer(
              $db: $db,
              $table: $db.playbackQueues,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SongsTableFilterComposer get songId {
    final $$SongsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.songId,
        referencedTable: $db.songs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SongsTableFilterComposer(
              $db: $db,
              $table: $db.songs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$QueueSongsTableOrderingComposer
    extends Composer<_$AppDatabase, $QueueSongsTable> {
  $$QueueSongsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get listKind => $composableBuilder(
      column: $table.listKind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  $$PlaybackQueuesTableOrderingComposer get queueId {
    final $$PlaybackQueuesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.queueId,
        referencedTable: $db.playbackQueues,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaybackQueuesTableOrderingComposer(
              $db: $db,
              $table: $db.playbackQueues,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SongsTableOrderingComposer get songId {
    final $$SongsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.songId,
        referencedTable: $db.songs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SongsTableOrderingComposer(
              $db: $db,
              $table: $db.songs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$QueueSongsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QueueSongsTable> {
  $$QueueSongsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get listKind =>
      $composableBuilder(column: $table.listKind, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$PlaybackQueuesTableAnnotationComposer get queueId {
    final $$PlaybackQueuesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.queueId,
        referencedTable: $db.playbackQueues,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaybackQueuesTableAnnotationComposer(
              $db: $db,
              $table: $db.playbackQueues,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SongsTableAnnotationComposer get songId {
    final $$SongsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.songId,
        referencedTable: $db.songs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SongsTableAnnotationComposer(
              $db: $db,
              $table: $db.songs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$QueueSongsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QueueSongsTable,
    QueueSongRow,
    $$QueueSongsTableFilterComposer,
    $$QueueSongsTableOrderingComposer,
    $$QueueSongsTableAnnotationComposer,
    $$QueueSongsTableCreateCompanionBuilder,
    $$QueueSongsTableUpdateCompanionBuilder,
    (QueueSongRow, $$QueueSongsTableReferences),
    QueueSongRow,
    PrefetchHooks Function({bool queueId, bool songId})> {
  $$QueueSongsTableTableManager(_$AppDatabase db, $QueueSongsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QueueSongsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QueueSongsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QueueSongsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> queueId = const Value.absent(),
            Value<String> listKind = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<String> songId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              QueueSongsCompanion(
            queueId: queueId,
            listKind: listKind,
            position: position,
            songId: songId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String queueId,
            required String listKind,
            required int position,
            required String songId,
            Value<int> rowid = const Value.absent(),
          }) =>
              QueueSongsCompanion.insert(
            queueId: queueId,
            listKind: listKind,
            position: position,
            songId: songId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$QueueSongsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({queueId = false, songId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (queueId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.queueId,
                    referencedTable:
                        $$QueueSongsTableReferences._queueIdTable(db),
                    referencedColumn:
                        $$QueueSongsTableReferences._queueIdTable(db).id,
                  ) as T;
                }
                if (songId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.songId,
                    referencedTable:
                        $$QueueSongsTableReferences._songIdTable(db),
                    referencedColumn:
                        $$QueueSongsTableReferences._songIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$QueueSongsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QueueSongsTable,
    QueueSongRow,
    $$QueueSongsTableFilterComposer,
    $$QueueSongsTableOrderingComposer,
    $$QueueSongsTableAnnotationComposer,
    $$QueueSongsTableCreateCompanionBuilder,
    $$QueueSongsTableUpdateCompanionBuilder,
    (QueueSongRow, $$QueueSongsTableReferences),
    QueueSongRow,
    PrefetchHooks Function({bool queueId, bool songId})>;
typedef $$PlaybackSettingsTableTableCreateCompanionBuilder
    = PlaybackSettingsTableCompanion Function({
  Value<int> id,
  required CrossfadeMode crossfadeMode,
  required int crossfadeDurationMs,
  required int speedHundredths,
  required bool pitchCorrectionEnabled,
});
typedef $$PlaybackSettingsTableTableUpdateCompanionBuilder
    = PlaybackSettingsTableCompanion Function({
  Value<int> id,
  Value<CrossfadeMode> crossfadeMode,
  Value<int> crossfadeDurationMs,
  Value<int> speedHundredths,
  Value<bool> pitchCorrectionEnabled,
});

class $$PlaybackSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PlaybackSettingsTableTable> {
  $$PlaybackSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<CrossfadeMode, CrossfadeMode, String>
      get crossfadeMode => $composableBuilder(
          column: $table.crossfadeMode,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get crossfadeDurationMs => $composableBuilder(
      column: $table.crossfadeDurationMs,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get speedHundredths => $composableBuilder(
      column: $table.speedHundredths,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get pitchCorrectionEnabled => $composableBuilder(
      column: $table.pitchCorrectionEnabled,
      builder: (column) => ColumnFilters(column));
}

class $$PlaybackSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaybackSettingsTableTable> {
  $$PlaybackSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get crossfadeMode => $composableBuilder(
      column: $table.crossfadeMode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get crossfadeDurationMs => $composableBuilder(
      column: $table.crossfadeDurationMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get speedHundredths => $composableBuilder(
      column: $table.speedHundredths,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pitchCorrectionEnabled => $composableBuilder(
      column: $table.pitchCorrectionEnabled,
      builder: (column) => ColumnOrderings(column));
}

class $$PlaybackSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaybackSettingsTableTable> {
  $$PlaybackSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CrossfadeMode, String> get crossfadeMode =>
      $composableBuilder(
          column: $table.crossfadeMode, builder: (column) => column);

  GeneratedColumn<int> get crossfadeDurationMs => $composableBuilder(
      column: $table.crossfadeDurationMs, builder: (column) => column);

  GeneratedColumn<int> get speedHundredths => $composableBuilder(
      column: $table.speedHundredths, builder: (column) => column);

  GeneratedColumn<bool> get pitchCorrectionEnabled => $composableBuilder(
      column: $table.pitchCorrectionEnabled, builder: (column) => column);
}

class $$PlaybackSettingsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlaybackSettingsTableTable,
    PlaybackSettingsRow,
    $$PlaybackSettingsTableTableFilterComposer,
    $$PlaybackSettingsTableTableOrderingComposer,
    $$PlaybackSettingsTableTableAnnotationComposer,
    $$PlaybackSettingsTableTableCreateCompanionBuilder,
    $$PlaybackSettingsTableTableUpdateCompanionBuilder,
    (
      PlaybackSettingsRow,
      BaseReferences<_$AppDatabase, $PlaybackSettingsTableTable,
          PlaybackSettingsRow>
    ),
    PlaybackSettingsRow,
    PrefetchHooks Function()> {
  $$PlaybackSettingsTableTableTableManager(
      _$AppDatabase db, $PlaybackSettingsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaybackSettingsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaybackSettingsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaybackSettingsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<CrossfadeMode> crossfadeMode = const Value.absent(),
            Value<int> crossfadeDurationMs = const Value.absent(),
            Value<int> speedHundredths = const Value.absent(),
            Value<bool> pitchCorrectionEnabled = const Value.absent(),
          }) =>
              PlaybackSettingsTableCompanion(
            id: id,
            crossfadeMode: crossfadeMode,
            crossfadeDurationMs: crossfadeDurationMs,
            speedHundredths: speedHundredths,
            pitchCorrectionEnabled: pitchCorrectionEnabled,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required CrossfadeMode crossfadeMode,
            required int crossfadeDurationMs,
            required int speedHundredths,
            required bool pitchCorrectionEnabled,
          }) =>
              PlaybackSettingsTableCompanion.insert(
            id: id,
            crossfadeMode: crossfadeMode,
            crossfadeDurationMs: crossfadeDurationMs,
            speedHundredths: speedHundredths,
            pitchCorrectionEnabled: pitchCorrectionEnabled,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlaybackSettingsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $PlaybackSettingsTableTable,
        PlaybackSettingsRow,
        $$PlaybackSettingsTableTableFilterComposer,
        $$PlaybackSettingsTableTableOrderingComposer,
        $$PlaybackSettingsTableTableAnnotationComposer,
        $$PlaybackSettingsTableTableCreateCompanionBuilder,
        $$PlaybackSettingsTableTableUpdateCompanionBuilder,
        (
          PlaybackSettingsRow,
          BaseReferences<_$AppDatabase, $PlaybackSettingsTableTable,
              PlaybackSettingsRow>
        ),
        PlaybackSettingsRow,
        PrefetchHooks Function()>;
typedef $$ActiveSessionTableTableCreateCompanionBuilder
    = ActiveSessionTableCompanion Function({
  Value<int> id,
  required String activeQueueId,
  required int positionMs,
});
typedef $$ActiveSessionTableTableUpdateCompanionBuilder
    = ActiveSessionTableCompanion Function({
  Value<int> id,
  Value<String> activeQueueId,
  Value<int> positionMs,
});

class $$ActiveSessionTableTableFilterComposer
    extends Composer<_$AppDatabase, $ActiveSessionTableTable> {
  $$ActiveSessionTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activeQueueId => $composableBuilder(
      column: $table.activeQueueId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get positionMs => $composableBuilder(
      column: $table.positionMs, builder: (column) => ColumnFilters(column));
}

class $$ActiveSessionTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ActiveSessionTableTable> {
  $$ActiveSessionTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activeQueueId => $composableBuilder(
      column: $table.activeQueueId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get positionMs => $composableBuilder(
      column: $table.positionMs, builder: (column) => ColumnOrderings(column));
}

class $$ActiveSessionTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActiveSessionTableTable> {
  $$ActiveSessionTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get activeQueueId => $composableBuilder(
      column: $table.activeQueueId, builder: (column) => column);

  GeneratedColumn<int> get positionMs => $composableBuilder(
      column: $table.positionMs, builder: (column) => column);
}

class $$ActiveSessionTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ActiveSessionTableTable,
    ActiveSessionRow,
    $$ActiveSessionTableTableFilterComposer,
    $$ActiveSessionTableTableOrderingComposer,
    $$ActiveSessionTableTableAnnotationComposer,
    $$ActiveSessionTableTableCreateCompanionBuilder,
    $$ActiveSessionTableTableUpdateCompanionBuilder,
    (
      ActiveSessionRow,
      BaseReferences<_$AppDatabase, $ActiveSessionTableTable, ActiveSessionRow>
    ),
    ActiveSessionRow,
    PrefetchHooks Function()> {
  $$ActiveSessionTableTableTableManager(
      _$AppDatabase db, $ActiveSessionTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActiveSessionTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActiveSessionTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActiveSessionTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> activeQueueId = const Value.absent(),
            Value<int> positionMs = const Value.absent(),
          }) =>
              ActiveSessionTableCompanion(
            id: id,
            activeQueueId: activeQueueId,
            positionMs: positionMs,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String activeQueueId,
            required int positionMs,
          }) =>
              ActiveSessionTableCompanion.insert(
            id: id,
            activeQueueId: activeQueueId,
            positionMs: positionMs,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ActiveSessionTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ActiveSessionTableTable,
    ActiveSessionRow,
    $$ActiveSessionTableTableFilterComposer,
    $$ActiveSessionTableTableOrderingComposer,
    $$ActiveSessionTableTableAnnotationComposer,
    $$ActiveSessionTableTableCreateCompanionBuilder,
    $$ActiveSessionTableTableUpdateCompanionBuilder,
    (
      ActiveSessionRow,
      BaseReferences<_$AppDatabase, $ActiveSessionTableTable, ActiveSessionRow>
    ),
    ActiveSessionRow,
    PrefetchHooks Function()>;
typedef $$PlaylistsTableCreateCompanionBuilder = PlaylistsCompanion Function({
  required String id,
  required String name,
  required int dateCreatedUtcMs,
  Value<int> rowid,
});
typedef $$PlaylistsTableUpdateCompanionBuilder = PlaylistsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> dateCreatedUtcMs,
  Value<int> rowid,
});

final class $$PlaylistsTableReferences
    extends BaseReferences<_$AppDatabase, $PlaylistsTable, PlaylistRow> {
  $$PlaylistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlaylistSongsTable, List<PlaylistSongRow>>
      _playlistSongsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.playlistSongs,
              aliasName: 'playlists__id__playlist_songs__playlist_id');

  $$PlaylistSongsTableProcessedTableManager get playlistSongsRefs {
    final manager = $$PlaylistSongsTableTableManager($_db, $_db.playlistSongs)
        .filter((f) => f.playlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_playlistSongsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$PlaylistsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dateCreatedUtcMs => $composableBuilder(
      column: $table.dateCreatedUtcMs,
      builder: (column) => ColumnFilters(column));

  Expression<bool> playlistSongsRefs(
      Expression<bool> Function($$PlaylistSongsTableFilterComposer f) f) {
    final $$PlaylistSongsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.playlistSongs,
        getReferencedColumn: (t) => t.playlistId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistSongsTableFilterComposer(
              $db: $db,
              $table: $db.playlistSongs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PlaylistsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dateCreatedUtcMs => $composableBuilder(
      column: $table.dateCreatedUtcMs,
      builder: (column) => ColumnOrderings(column));
}

class $$PlaylistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistsTable> {
  $$PlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get dateCreatedUtcMs => $composableBuilder(
      column: $table.dateCreatedUtcMs, builder: (column) => column);

  Expression<T> playlistSongsRefs<T extends Object>(
      Expression<T> Function($$PlaylistSongsTableAnnotationComposer a) f) {
    final $$PlaylistSongsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.playlistSongs,
        getReferencedColumn: (t) => t.playlistId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistSongsTableAnnotationComposer(
              $db: $db,
              $table: $db.playlistSongs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$PlaylistsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlaylistsTable,
    PlaylistRow,
    $$PlaylistsTableFilterComposer,
    $$PlaylistsTableOrderingComposer,
    $$PlaylistsTableAnnotationComposer,
    $$PlaylistsTableCreateCompanionBuilder,
    $$PlaylistsTableUpdateCompanionBuilder,
    (PlaylistRow, $$PlaylistsTableReferences),
    PlaylistRow,
    PrefetchHooks Function({bool playlistSongsRefs})> {
  $$PlaylistsTableTableManager(_$AppDatabase db, $PlaylistsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> dateCreatedUtcMs = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlaylistsCompanion(
            id: id,
            name: name,
            dateCreatedUtcMs: dateCreatedUtcMs,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required int dateCreatedUtcMs,
            Value<int> rowid = const Value.absent(),
          }) =>
              PlaylistsCompanion.insert(
            id: id,
            name: name,
            dateCreatedUtcMs: dateCreatedUtcMs,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PlaylistsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({playlistSongsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (playlistSongsRefs) db.playlistSongs
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (playlistSongsRefs)
                    await $_getPrefetchedData<PlaylistRow, $PlaylistsTable,
                            PlaylistSongRow>(
                        currentTable: table,
                        referencedTable: $$PlaylistsTableReferences
                            ._playlistSongsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$PlaylistsTableReferences(db, table, p0)
                                .playlistSongsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.playlistId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$PlaylistsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlaylistsTable,
    PlaylistRow,
    $$PlaylistsTableFilterComposer,
    $$PlaylistsTableOrderingComposer,
    $$PlaylistsTableAnnotationComposer,
    $$PlaylistsTableCreateCompanionBuilder,
    $$PlaylistsTableUpdateCompanionBuilder,
    (PlaylistRow, $$PlaylistsTableReferences),
    PlaylistRow,
    PrefetchHooks Function({bool playlistSongsRefs})>;
typedef $$PlaylistSongsTableCreateCompanionBuilder = PlaylistSongsCompanion
    Function({
  required String playlistId,
  required int position,
  required String songId,
  Value<int> rowid,
});
typedef $$PlaylistSongsTableUpdateCompanionBuilder = PlaylistSongsCompanion
    Function({
  Value<String> playlistId,
  Value<int> position,
  Value<String> songId,
  Value<int> rowid,
});

final class $$PlaylistSongsTableReferences extends BaseReferences<_$AppDatabase,
    $PlaylistSongsTable, PlaylistSongRow> {
  $$PlaylistSongsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $PlaylistsTable _playlistIdTable(_$AppDatabase db) =>
      db.playlists.createAlias('playlist_songs__playlist_id__playlists__id');

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<String>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager($_db, $_db.playlists)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $SongsTable _songIdTable(_$AppDatabase db) =>
      db.songs.createAlias('playlist_songs__song_id__songs__id');

  $$SongsTableProcessedTableManager get songId {
    final $_column = $_itemColumn<String>('song_id')!;

    final manager = $$SongsTableTableManager($_db, $_db.songs)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_songIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PlaylistSongsTableFilterComposer
    extends Composer<_$AppDatabase, $PlaylistSongsTable> {
  $$PlaylistSongsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.playlistId,
        referencedTable: $db.playlists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistsTableFilterComposer(
              $db: $db,
              $table: $db.playlists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SongsTableFilterComposer get songId {
    final $$SongsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.songId,
        referencedTable: $db.songs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SongsTableFilterComposer(
              $db: $db,
              $table: $db.songs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PlaylistSongsTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaylistSongsTable> {
  $$PlaylistSongsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.playlistId,
        referencedTable: $db.playlists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistsTableOrderingComposer(
              $db: $db,
              $table: $db.playlists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SongsTableOrderingComposer get songId {
    final $$SongsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.songId,
        referencedTable: $db.songs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SongsTableOrderingComposer(
              $db: $db,
              $table: $db.songs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PlaylistSongsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaylistSongsTable> {
  $$PlaylistSongsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.playlistId,
        referencedTable: $db.playlists,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PlaylistsTableAnnotationComposer(
              $db: $db,
              $table: $db.playlists,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$SongsTableAnnotationComposer get songId {
    final $$SongsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.songId,
        referencedTable: $db.songs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SongsTableAnnotationComposer(
              $db: $db,
              $table: $db.songs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PlaylistSongsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlaylistSongsTable,
    PlaylistSongRow,
    $$PlaylistSongsTableFilterComposer,
    $$PlaylistSongsTableOrderingComposer,
    $$PlaylistSongsTableAnnotationComposer,
    $$PlaylistSongsTableCreateCompanionBuilder,
    $$PlaylistSongsTableUpdateCompanionBuilder,
    (PlaylistSongRow, $$PlaylistSongsTableReferences),
    PlaylistSongRow,
    PrefetchHooks Function({bool playlistId, bool songId})> {
  $$PlaylistSongsTableTableManager(_$AppDatabase db, $PlaylistSongsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistSongsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistSongsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistSongsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> playlistId = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<String> songId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlaylistSongsCompanion(
            playlistId: playlistId,
            position: position,
            songId: songId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String playlistId,
            required int position,
            required String songId,
            Value<int> rowid = const Value.absent(),
          }) =>
              PlaylistSongsCompanion.insert(
            playlistId: playlistId,
            position: position,
            songId: songId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PlaylistSongsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({playlistId = false, songId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (playlistId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.playlistId,
                    referencedTable:
                        $$PlaylistSongsTableReferences._playlistIdTable(db),
                    referencedColumn:
                        $$PlaylistSongsTableReferences._playlistIdTable(db).id,
                  ) as T;
                }
                if (songId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.songId,
                    referencedTable:
                        $$PlaylistSongsTableReferences._songIdTable(db),
                    referencedColumn:
                        $$PlaylistSongsTableReferences._songIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PlaylistSongsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlaylistSongsTable,
    PlaylistSongRow,
    $$PlaylistSongsTableFilterComposer,
    $$PlaylistSongsTableOrderingComposer,
    $$PlaylistSongsTableAnnotationComposer,
    $$PlaylistSongsTableCreateCompanionBuilder,
    $$PlaylistSongsTableUpdateCompanionBuilder,
    (PlaylistSongRow, $$PlaylistSongsTableReferences),
    PlaylistSongRow,
    PrefetchHooks Function({bool playlistId, bool songId})>;
typedef $$PlaybackHistoryTableCreateCompanionBuilder = PlaybackHistoryCompanion
    Function({
  Value<int> id,
  required String songId,
  required int timestampUtcMs,
});
typedef $$PlaybackHistoryTableUpdateCompanionBuilder = PlaybackHistoryCompanion
    Function({
  Value<int> id,
  Value<String> songId,
  Value<int> timestampUtcMs,
});

final class $$PlaybackHistoryTableReferences extends BaseReferences<
    _$AppDatabase, $PlaybackHistoryTable, PlaybackHistoryRow> {
  $$PlaybackHistoryTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $SongsTable _songIdTable(_$AppDatabase db) =>
      db.songs.createAlias('playback_history__song_id__songs__id');

  $$SongsTableProcessedTableManager get songId {
    final $_column = $_itemColumn<String>('song_id')!;

    final manager = $$SongsTableTableManager($_db, $_db.songs)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_songIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PlaybackHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $PlaybackHistoryTable> {
  $$PlaybackHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timestampUtcMs => $composableBuilder(
      column: $table.timestampUtcMs,
      builder: (column) => ColumnFilters(column));

  $$SongsTableFilterComposer get songId {
    final $$SongsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.songId,
        referencedTable: $db.songs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SongsTableFilterComposer(
              $db: $db,
              $table: $db.songs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PlaybackHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $PlaybackHistoryTable> {
  $$PlaybackHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timestampUtcMs => $composableBuilder(
      column: $table.timestampUtcMs,
      builder: (column) => ColumnOrderings(column));

  $$SongsTableOrderingComposer get songId {
    final $$SongsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.songId,
        referencedTable: $db.songs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SongsTableOrderingComposer(
              $db: $db,
              $table: $db.songs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PlaybackHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $PlaybackHistoryTable> {
  $$PlaybackHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get timestampUtcMs => $composableBuilder(
      column: $table.timestampUtcMs, builder: (column) => column);

  $$SongsTableAnnotationComposer get songId {
    final $$SongsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.songId,
        referencedTable: $db.songs,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SongsTableAnnotationComposer(
              $db: $db,
              $table: $db.songs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PlaybackHistoryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlaybackHistoryTable,
    PlaybackHistoryRow,
    $$PlaybackHistoryTableFilterComposer,
    $$PlaybackHistoryTableOrderingComposer,
    $$PlaybackHistoryTableAnnotationComposer,
    $$PlaybackHistoryTableCreateCompanionBuilder,
    $$PlaybackHistoryTableUpdateCompanionBuilder,
    (PlaybackHistoryRow, $$PlaybackHistoryTableReferences),
    PlaybackHistoryRow,
    PrefetchHooks Function({bool songId})> {
  $$PlaybackHistoryTableTableManager(
      _$AppDatabase db, $PlaybackHistoryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaybackHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaybackHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaybackHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> songId = const Value.absent(),
            Value<int> timestampUtcMs = const Value.absent(),
          }) =>
              PlaybackHistoryCompanion(
            id: id,
            songId: songId,
            timestampUtcMs: timestampUtcMs,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String songId,
            required int timestampUtcMs,
          }) =>
              PlaybackHistoryCompanion.insert(
            id: id,
            songId: songId,
            timestampUtcMs: timestampUtcMs,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PlaybackHistoryTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({songId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (songId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.songId,
                    referencedTable:
                        $$PlaybackHistoryTableReferences._songIdTable(db),
                    referencedColumn:
                        $$PlaybackHistoryTableReferences._songIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PlaybackHistoryTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PlaybackHistoryTable,
    PlaybackHistoryRow,
    $$PlaybackHistoryTableFilterComposer,
    $$PlaybackHistoryTableOrderingComposer,
    $$PlaybackHistoryTableAnnotationComposer,
    $$PlaybackHistoryTableCreateCompanionBuilder,
    $$PlaybackHistoryTableUpdateCompanionBuilder,
    (PlaybackHistoryRow, $$PlaybackHistoryTableReferences),
    PlaybackHistoryRow,
    PrefetchHooks Function({bool songId})>;
typedef $$ItemInteractionsTableCreateCompanionBuilder
    = ItemInteractionsCompanion Function({
  required String itemId,
  required String itemType,
  required int interaction,
  required int timestampUtcMs,
  Value<int> rowid,
});
typedef $$ItemInteractionsTableUpdateCompanionBuilder
    = ItemInteractionsCompanion Function({
  Value<String> itemId,
  Value<String> itemType,
  Value<int> interaction,
  Value<int> timestampUtcMs,
  Value<int> rowid,
});

class $$ItemInteractionsTableFilterComposer
    extends Composer<_$AppDatabase, $ItemInteractionsTable> {
  $$ItemInteractionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemType => $composableBuilder(
      column: $table.itemType, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get interaction => $composableBuilder(
      column: $table.interaction, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get timestampUtcMs => $composableBuilder(
      column: $table.timestampUtcMs,
      builder: (column) => ColumnFilters(column));
}

class $$ItemInteractionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemInteractionsTable> {
  $$ItemInteractionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemType => $composableBuilder(
      column: $table.itemType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get interaction => $composableBuilder(
      column: $table.interaction, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get timestampUtcMs => $composableBuilder(
      column: $table.timestampUtcMs,
      builder: (column) => ColumnOrderings(column));
}

class $$ItemInteractionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemInteractionsTable> {
  $$ItemInteractionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<int> get interaction => $composableBuilder(
      column: $table.interaction, builder: (column) => column);

  GeneratedColumn<int> get timestampUtcMs => $composableBuilder(
      column: $table.timestampUtcMs, builder: (column) => column);
}

class $$ItemInteractionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ItemInteractionsTable,
    ItemInteractionRow,
    $$ItemInteractionsTableFilterComposer,
    $$ItemInteractionsTableOrderingComposer,
    $$ItemInteractionsTableAnnotationComposer,
    $$ItemInteractionsTableCreateCompanionBuilder,
    $$ItemInteractionsTableUpdateCompanionBuilder,
    (
      ItemInteractionRow,
      BaseReferences<_$AppDatabase, $ItemInteractionsTable, ItemInteractionRow>
    ),
    ItemInteractionRow,
    PrefetchHooks Function()> {
  $$ItemInteractionsTableTableManager(
      _$AppDatabase db, $ItemInteractionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemInteractionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemInteractionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemInteractionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> itemId = const Value.absent(),
            Value<String> itemType = const Value.absent(),
            Value<int> interaction = const Value.absent(),
            Value<int> timestampUtcMs = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ItemInteractionsCompanion(
            itemId: itemId,
            itemType: itemType,
            interaction: interaction,
            timestampUtcMs: timestampUtcMs,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String itemId,
            required String itemType,
            required int interaction,
            required int timestampUtcMs,
            Value<int> rowid = const Value.absent(),
          }) =>
              ItemInteractionsCompanion.insert(
            itemId: itemId,
            itemType: itemType,
            interaction: interaction,
            timestampUtcMs: timestampUtcMs,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ItemInteractionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ItemInteractionsTable,
    ItemInteractionRow,
    $$ItemInteractionsTableFilterComposer,
    $$ItemInteractionsTableOrderingComposer,
    $$ItemInteractionsTableAnnotationComposer,
    $$ItemInteractionsTableCreateCompanionBuilder,
    $$ItemInteractionsTableUpdateCompanionBuilder,
    (
      ItemInteractionRow,
      BaseReferences<_$AppDatabase, $ItemInteractionsTable, ItemInteractionRow>
    ),
    ItemInteractionRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SongsTableTableManager get songs =>
      $$SongsTableTableManager(_db, _db.songs);
  $$PlaybackQueuesTableTableManager get playbackQueues =>
      $$PlaybackQueuesTableTableManager(_db, _db.playbackQueues);
  $$QueueSongsTableTableManager get queueSongs =>
      $$QueueSongsTableTableManager(_db, _db.queueSongs);
  $$PlaybackSettingsTableTableTableManager get playbackSettingsTable =>
      $$PlaybackSettingsTableTableTableManager(_db, _db.playbackSettingsTable);
  $$ActiveSessionTableTableTableManager get activeSessionTable =>
      $$ActiveSessionTableTableTableManager(_db, _db.activeSessionTable);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db, _db.playlists);
  $$PlaylistSongsTableTableManager get playlistSongs =>
      $$PlaylistSongsTableTableManager(_db, _db.playlistSongs);
  $$PlaybackHistoryTableTableManager get playbackHistory =>
      $$PlaybackHistoryTableTableManager(_db, _db.playbackHistory);
  $$ItemInteractionsTableTableManager get itemInteractions =>
      $$ItemInteractionsTableTableManager(_db, _db.itemInteractions);
}
