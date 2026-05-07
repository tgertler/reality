import 'package:logger/logger.dart';
import 'package:postgrest/postgrest.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/show.dart';
import '../../domain/entities/season.dart';
import '../../domain/entities/attendee.dart';

String _toDatabaseTimestamptz(DateTime value) =>
    value.toUtc().toIso8601String();

Map<String, String>? _toUtcSeasonReleaseParts({
  DateTime? startDate,
  String? streamingReleaseTime,
}) {
  if (startDate == null) return null;

  var hour = startDate.hour;
  var minute = startDate.minute;
  var second = startDate.second;

  final rawTime = streamingReleaseTime?.trim();
  if (rawTime != null && rawTime.isNotEmpty) {
    final parts = rawTime.split(':');
    hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? hour : hour;
    minute = parts.length > 1 ? int.tryParse(parts[1]) ?? minute : minute;
    second = parts.length > 2
        ? int.tryParse(parts[2].split('.').first) ?? second
        : 0;
  }

  final localRelease = DateTime(
    startDate.year,
    startDate.month,
    startDate.day,
    hour,
    minute,
    second,
  );
  final utcRelease = localRelease.toUtc();

  return {
    'date':
        '${utcRelease.year.toString().padLeft(4, '0')}-${utcRelease.month.toString().padLeft(2, '0')}-${utcRelease.day.toString().padLeft(2, '0')}',
    'time':
        '${utcRelease.hour.toString().padLeft(2, '0')}:${utcRelease.minute.toString().padLeft(2, '0')}:${utcRelease.second.toString().padLeft(2, '0')}',
  };
}

Map<String, dynamic> buildShowEventCalendarPayload({
  required String showEventId,
  required DateTime startDatetime,
  required String eventSubtype,
  Duration? duration,
}) {
  final normalizedSubtype = eventSubtype.toLowerCase();
  final eventType = normalizedSubtype == 'premiere'
      ? 'premiere'
      : normalizedSubtype == 'finale'
          ? 'finale'
          : normalizedSubtype == 'reunion'
              ? 'reunion'
              : 'regular';
  final end = startDatetime.add(duration ?? const Duration(hours: 1));

  return {
    'id': const Uuid().v4(),
    'start_datetime': _toDatabaseTimestamptz(startDatetime),
    'end_datetime': _toDatabaseTimestamptz(end),
    'event_type': eventType,
    'event_entity_type': 'show_event',
    'show_event_id': showEventId,
  };
}

class ContentDataSource {
  final SupabaseClient supabaseClient;
  final Logger _logger = getLogger('ContentDataSource');

  ContentDataSource(this.supabaseClient);

  Future<void> addShow(Show show) async {
    _logger.i('Adding show: ${show.toJson()}');
    await supabaseClient.from('shows').insert(show.toJson());
    _logger.i('Show added successfully');
  }

  Future<void> updateShow({
    required String showId,
    String? title,
    String? shortTitle,
    String? description,
    String? genre,
    String? releaseWindow,
    String? status,
    String? slug,
    String? tmdbId,
    String? traktSlug,
    String? headerImageUrl,
    String? mainColor,
  }) async {
    final payload = <String, dynamic>{
      if (title != null) 'title': title,
      if (shortTitle != null) 'short_title': shortTitle,
      if (description != null) 'description': description,
      if (genre != null) 'genre': genre,
      if (releaseWindow != null) 'release_window': releaseWindow,
      if (status != null) 'status': status,
      if (slug != null) 'slug': slug,
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (traktSlug != null) 'trakt_slug': traktSlug,
      if (headerImageUrl != null) 'header_image': headerImageUrl,
      if (mainColor != null) 'main_color': mainColor,
    };
    if (payload.isEmpty) return;
    await supabaseClient.from('shows').update(payload).eq('id', showId);
  }

  Future<List<Map<String, dynamic>>> getShowsTableRows() async {
    final response = await supabaseClient
        .from('shows')
        .select(
            'id, title, short_title, description, genre, release_window, status, slug, tmdb_id, trakt_slug, header_image, main_color, created_at, updated_at')
        .order('title', ascending: true);
    return (response as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getSeasonsTableRowsByShowId(
      String showId) async {
    final response = await supabaseClient
        .from('seasons')
        .select(
            'id, show_id, season_number, total_episodes, release_frequency, streaming_release_time, streaming_release_date, episode_length, streaming_option, status, release_days, created_at, updated_at')
        .eq('show_id', showId)
        .order('season_number', ascending: true);
    return (response as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getShowEventsBySeasonId(
      String seasonId) async {
    final response = await supabaseClient
        .from('show_events')
        .select(
            'id, show_id, season_id, event_subtype, episode_number, description, created_at, calendar_events(id, start_datetime, end_datetime, event_type, event_entity_type, drama_level, created_at)')
        .eq('season_id', seasonId)
        .order('episode_number', ascending: true);
    final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();
    return rows.map((row) {
      final dynamic calendarRaw = row['calendar_events'];
      Map<String, dynamic>? calendarEvent;
      if (calendarRaw is List && calendarRaw.isNotEmpty) {
        final first = calendarRaw.first;
        if (first is Map<String, dynamic>) {
          calendarEvent = first;
        }
      } else if (calendarRaw is Map<String, dynamic>) {
        calendarEvent = calendarRaw;
      }

      return {
        ...row,
        'calendar_event': calendarEvent,
        'calendar_event_id': calendarEvent?['id'],
        'calendar_start_datetime': calendarEvent?['start_datetime'],
        'calendar_end_datetime': calendarEvent?['end_datetime'],
        'calendar_event_type': calendarEvent?['event_type'],
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getCalendarEventsByShowEventId(
      String showEventId) async {
    final response = await supabaseClient
        .from('calendar_events')
        .select(
            'id, start_datetime, end_datetime, event_type, drama_level, event_entity_type, show_event_id, creator_event_id, trash_event_id, created_at')
        .eq('show_event_id', showEventId)
        .order('start_datetime', ascending: true);
    return (response as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> addSeason(Season season) async {
    _logger.i('Adding season: ${season.toJson()}');
    await supabaseClient.from('seasons').insert(season.toJson());
    _logger.i('Season added successfully');
  }

  Future<void> updateSeason({
    required String seasonId,
    String? showId,
    int? seasonNumber,
    int? totalEpisodes,
    String? releaseFrequency,
    DateTime? startDate,
    String? streamingReleaseTime,
    int? episodeLength,
    String? streamingOption,
    String? status,
  }) async {
    final normalizedFrequency = _normalizeFrequency(releaseFrequency);
    final releaseDays = _parseMultiWeeklyDays(releaseFrequency).toList()
      ..sort();
    final releaseParts = _toUtcSeasonReleaseParts(
      startDate: startDate,
      streamingReleaseTime: streamingReleaseTime,
    );

    final payload = <String, dynamic>{
      if (showId != null) 'show_id': showId,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (totalEpisodes != null) 'total_episodes': totalEpisodes,
      if (releaseFrequency != null) 'release_frequency': normalizedFrequency,
      if (releaseParts != null) 'streaming_release_date': releaseParts['date'],
      if (releaseParts != null) 'streaming_release_time': releaseParts['time'],
      if (episodeLength != null) 'episode_length': episodeLength,
      if (streamingOption != null && streamingOption.trim().isNotEmpty)
        'streaming_option': streamingOption.trim().length <= 20
            ? streamingOption.trim()
            : streamingOption.trim().substring(0, 20),
      if (status != null) 'status': status,
      if (releaseFrequency != null && normalizedFrequency == 'multi_weekly')
        'release_days': releaseDays,
    };
    if (payload.isEmpty) return;
    await supabaseClient.from('seasons').update(payload).eq('id', seasonId);
  }

  Future<void> addAttendee(Attendee attendee) async {
    _logger.i('Adding attendee: ${attendee.toJson()}');
    await supabaseClient.from('attendees').insert(attendee.toJson());
    _logger.i('Attendee added successfully');
  }

  Future<void> generateCalendarEvents(Season season) async {
    _logger.i('Generating calendar events for season: ${season.toJson()}');

    // ── Step 1: create show_events ──────────────────────────────────────────
    final List<Map<String, dynamic>> showEventPayloads = [];
    final releaseDates = _generateReleaseDates(
      startDate: season.startDate!,
      totalEpisodes: season.totalEpisodes!,
      releaseFrequency: season.releaseFrequency,
    );

    for (int i = 0; i < season.totalEpisodes!; i++) {
      String eventSubtype = 'episode';
      if (i == 0) {
        eventSubtype = 'premiere';
      } else if (i == season.totalEpisodes! - 1) {
        eventSubtype = 'finale';
      }

      showEventPayloads.add({
        'id': Uuid().v4(),
        'show_id': season.showId!,
        'season_id': season.seasonId!,
        'event_subtype': eventSubtype,
        'episode_number': i + 1,
      });
    }

    final showEventRows = await supabaseClient
        .from('show_events')
        .insert(showEventPayloads)
        .select('id, episode_number, event_subtype');

    _logger.i('Created ${showEventRows.length} show_events');

    // ── Step 2: create calendar_events referencing the show_events ──────────
    // Re-iterate dates in sync with the inserted show_events order
    final List<Map<String, dynamic>> calendarEventPayloads = [];

    for (int i = 0; i < showEventRows.length; i++) {
      final showEvent = showEventRows[i];
      final subtype = showEvent['event_subtype'] as String;

      calendarEventPayloads.add(
        buildShowEventCalendarPayload(
          showEventId: showEvent['id'] as String,
          startDatetime: releaseDates[i],
          eventSubtype: subtype,
        ),
      );
    }

    if (calendarEventPayloads.isNotEmpty) {
      _logger.i(
          'Inserting calendar_events columns: ${calendarEventPayloads.first.keys.toList()}');
    }

    await supabaseClient.from('calendar_events').insert(calendarEventPayloads);

    _logger.i('Calendar events generated successfully');
  }

  List<DateTime> _generateReleaseDates({
    required DateTime startDate,
    required int totalEpisodes,
    required String? releaseFrequency,
  }) {
    final dates = <DateTime>[];
    final frequency = _normalizeFrequency(releaseFrequency);
    final multiWeeklyDays = _parseMultiWeeklyDays(releaseFrequency);

    if (frequency == 'premiere3_then_weekly') {
      for (var i = 0; i < totalEpisodes; i++) {
        if (i < 3) {
          dates.add(startDate);
        } else {
          dates.add(startDate.add(Duration(days: 7 * (i - 2))));
        }
      }
      return dates;
    }

    if (frequency == 'premiere2_then_weekly') {
      for (var i = 0; i < totalEpisodes; i++) {
        if (i < 2) {
          dates.add(startDate);
        } else {
          dates.add(startDate.add(Duration(days: 7 * (i - 1))));
        }
      }
      return dates;
    }

    if (frequency == 'weekly2' || frequency == 'weekly3') {
      final slots = frequency == 'weekly2' ? [0, 3] : [0, 2, 4];
      var index = 0;
      while (dates.length < totalEpisodes) {
        final weekOffset = Duration(days: 7 * (index ~/ slots.length));
        final slotOffset = Duration(days: slots[index % slots.length]);
        dates.add(startDate.add(weekOffset + slotOffset));
        index++;
      }
      return dates;
    }

    if (frequency == 'multi_weekly' && multiWeeklyDays.isNotEmpty) {
      var cursor = startDate;
      while (dates.length < totalEpisodes) {
        if (!cursor.isBefore(startDate) &&
            multiWeeklyDays.contains(cursor.weekday)) {
          dates.add(cursor);
        }
        cursor = cursor.add(const Duration(days: 1));
      }
      return dates;
    }

    var current = startDate;
    for (var i = 0; i < totalEpisodes; i++) {
      dates.add(current);
      switch (frequency) {
        case 'daily':
          current = current.add(const Duration(days: 1));
          break;
        case 'weekly':
          current = current.add(const Duration(days: 7));
          break;
        case 'biweekly':
          current = current.add(const Duration(days: 14));
          break;
        case 'monthly':
          current = DateTime(current.year, current.month + 1, current.day,
              current.hour, current.minute);
          break;
        case 'onetime':
          break;
        default:
          current = current.add(const Duration(days: 7));
      }
    }

    return dates;
  }

  String _normalizeFrequency(String? frequency) {
    if (frequency == null || frequency.isEmpty) return 'weekly';
    if (frequency.startsWith('multi_weekly')) return 'multi_weekly';
    if (frequency == 'premiere3_weekly') return 'premiere3_then_weekly';
    if (frequency == 'premiere2_weekly') return 'premiere2_then_weekly';
    return frequency;
  }

  Set<int> _parseMultiWeeklyDays(String? frequency) {
    if (frequency == null || !frequency.startsWith('multi_weekly:')) {
      return <int>{};
    }
    final raw = frequency.split(':').last;
    return raw
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .where((d) => d >= 1 && d <= 7)
        .toSet();
  }

  Future<List<Show>> getShows() async {
    final response = await supabaseClient
        .from('shows')
        .select('id, title, short_title')
        .order('title', ascending: true);
    final rows = response as List<dynamic>;
    return rows
        .map((e) => Show(
              showId: e['id'] as String,
              title: (e['title'] as String?) ?? '',
              shortTitle: e['short_title'] as String?,
            ))
        .toList();
  }

  Future<List<Season>> getSeasonsByShowId(String showId) async {
    final response = await supabaseClient
        .from('seasons')
        .select(
            'id, show_id, season_number, total_episodes, release_frequency, streaming_release_date, streaming_release_time, episode_length, streaming_option, release_days')
        .eq('show_id', showId)
        .order('season_number', ascending: true);

    final rows = response as List<dynamic>;
    return rows
        .map((e) => Season(
              seasonId: e['id'] as String,
              showId: e['show_id'] as String?,
              seasonNumber: e['season_number'] as int?,
              totalEpisodes: e['total_episodes'] as int?,
              releaseFrequency: _frequencyWithDays(
                e['release_frequency'] as String?,
                e['release_days'],
              ),
              startDate: _parseStreamingDateTime(
                e['streaming_release_date'] as String?,
                e['streaming_release_time']?.toString(),
              ),
              episodeLength: e['episode_length'] as int?,
              streamingOption: e['streaming_option'] as String?,
            ))
        .toList();
  }

  Future<List<Season>> getAllSeasons() async {
    final response = await supabaseClient
        .from('seasons')
        .select(
            'id, show_id, season_number, total_episodes, release_frequency, streaming_release_date, streaming_release_time, episode_length, streaming_option, release_days')
        .order('streaming_release_date', ascending: false);
    final rows = response as List<dynamic>;
    return rows
        .map((e) => Season(
              seasonId: e['id'] as String,
              showId: e['show_id'] as String?,
              seasonNumber: e['season_number'] as int?,
              totalEpisodes: e['total_episodes'] as int?,
              releaseFrequency: _frequencyWithDays(
                e['release_frequency'] as String?,
                e['release_days'],
              ),
              startDate: _parseStreamingDateTime(
                e['streaming_release_date'] as String?,
                e['streaming_release_time']?.toString(),
              ),
              episodeLength: e['episode_length'] as int?,
              streamingOption: e['streaming_option'] as String?,
            ))
        .toList();
  }

  String? _frequencyWithDays(String? frequency, dynamic releaseDaysRaw) {
    if (frequency != 'multi_weekly') return frequency;

    final releaseDays = _extractReleaseDays(releaseDaysRaw);
    if (releaseDays.isEmpty) return frequency;
    return 'multi_weekly:${releaseDays.join(',')}';
  }

  List<int> _extractReleaseDays(dynamic releaseDaysRaw) {
    if (releaseDaysRaw is! List) return const [];
    return releaseDaysRaw
        .map((e) => int.tryParse(e.toString()))
        .whereType<int>()
        .where((d) => d >= 1 && d <= 7)
        .toList();
  }

  DateTime? _parseStreamingDateTime(String? dateRaw, String? timeRaw) {
    if (dateRaw == null || dateRaw.isEmpty) return null;

    final parsedDate = DateTime.tryParse(dateRaw);
    if (parsedDate == null) return null;

    if (timeRaw == null || timeRaw.isEmpty) {
      return DateTime.utc(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
      ).toLocal();
    }

    final parts = timeRaw.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final second =
        parts.length > 2 ? int.tryParse(parts[2].split('.').first) ?? 0 : 0;

    return DateTime.utc(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      hour,
      minute,
      second,
    ).toLocal();
  }

  Future<List<Map<String, dynamic>>> getCreators() async {
    final response = await supabaseClient
        .from('creators')
        .select(
            'id, name, description, avatar_url, youtube_channel_url, instagram_url, tiktok_url')
        .order('name', ascending: true);
    return (response as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getCreatorEvents() async {
    final response = await supabaseClient
        .from('creator_events')
        .select(
            'id, creator_id, event_kind, related_show_id, related_season_id, episode_number, title, description, youtube_url, thumbnail_url, created_at, creators(name)')
        .order('created_at', ascending: false)
        .limit(300);
    return (response as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getTrashEvents() async {
    final response = await supabaseClient
        .from('trash_events')
        .select(
            'id, title, description, image_url, location, address, organizer, price, external_url, related_show_id, related_season_id, created_at')
        .order('created_at', ascending: false)
        .limit(300);
    return (response as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<String> addCreator({
    required String name,
    String? description,
    String? avatarUrl,
    String? youtubeChannelUrl,
    String? instagramUrl,
    String? tiktokUrl,
  }) async {
    final id = const Uuid().v4();
    await supabaseClient.from('creators').insert({
      'id': id,
      'name': name,
      'description': description,
      'avatar_url': avatarUrl,
      'youtube_channel_url': youtubeChannelUrl,
      'instagram_url': instagramUrl,
      'tiktok_url': tiktokUrl,
    });
    return id;
  }

  Future<void> updateCreator({
    required String creatorId,
    String? name,
    String? description,
    String? avatarUrl,
    String? youtubeChannelUrl,
    String? instagramUrl,
    String? tiktokUrl,
  }) async {
    final payload = <String, dynamic>{
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (youtubeChannelUrl != null) 'youtube_channel_url': youtubeChannelUrl,
      if (instagramUrl != null) 'instagram_url': instagramUrl,
      if (tiktokUrl != null) 'tiktok_url': tiktokUrl,
    };
    if (payload.isEmpty) return;
    await supabaseClient.from('creators').update(payload).eq('id', creatorId);
  }

  Future<void> addCreatorEvent({
    required String creatorId,
    required String eventKind,
    String? relatedShowId,
    String? relatedSeasonId,
    int? episodeNumber,
    String? title,
    String? description,
    String? youtubeUrl,
    String? thumbnailUrl,
    DateTime? scheduledAt,
    Duration? duration,
  }) async {
    final creatorEventId = const Uuid().v4();

    await supabaseClient.from('creator_events').insert({
      'id': creatorEventId,
      'creator_id': creatorId,
      'event_kind': eventKind,
      'related_show_id': relatedShowId,
      'related_season_id': relatedSeasonId,
      'episode_number': episodeNumber,
      'title': title,
      'description': description,
      'youtube_url': youtubeUrl,
      'thumbnail_url': thumbnailUrl,
    });

    if (scheduledAt != null) {
      final end = scheduledAt.add(duration ?? const Duration(hours: 1));
      await supabaseClient.from('calendar_events').insert({
        'id': const Uuid().v4(),
        'start_datetime': _toDatabaseTimestamptz(scheduledAt),
        'end_datetime': _toDatabaseTimestamptz(end),
        'event_type': 'creator',
        'event_entity_type': 'creator_event',
        'creator_event_id': creatorEventId,
      });
    }
  }

  Future<void> updateCreatorEvent({
    required String creatorEventId,
    String? creatorId,
    String? eventKind,
    String? relatedShowId,
    String? relatedSeasonId,
    int? episodeNumber,
    String? title,
    String? description,
    String? youtubeUrl,
    String? thumbnailUrl,
  }) async {
    final payload = <String, dynamic>{
      if (creatorId != null) 'creator_id': creatorId,
      if (eventKind != null) 'event_kind': eventKind,
      if (relatedShowId != null) 'related_show_id': relatedShowId,
      if (relatedSeasonId != null) 'related_season_id': relatedSeasonId,
      if (episodeNumber != null) 'episode_number': episodeNumber,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (youtubeUrl != null) 'youtube_url': youtubeUrl,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
    };
    if (payload.isEmpty) return;
    await supabaseClient
        .from('creator_events')
        .update(payload)
        .eq('id', creatorEventId);
  }

  Future<void> updateShowEvent({
    required String showEventId,
    String? showId,
    String? seasonId,
    String? eventSubtype,
    int? episodeNumber,
    String? description,
  }) async {
    final payload = <String, dynamic>{
      if (showId != null) 'show_id': showId,
      if (seasonId != null) 'season_id': seasonId,
      if (eventSubtype != null) 'event_subtype': eventSubtype,
      if (episodeNumber != null) 'episode_number': episodeNumber,
      if (description != null) 'description': description,
    };
    if (payload.isEmpty) return;
    await supabaseClient
        .from('show_events')
        .update(payload)
        .eq('id', showEventId);
  }

  Future<void> addShowEventWithCalendarEvent({
    required String showId,
    required String seasonId,
    required String eventSubtype,
    required int episodeNumber,
    String? description,
    required DateTime startDatetime,
    Duration? duration,
  }) async {
    final showEventId = const Uuid().v4();
    await supabaseClient.from('show_events').insert({
      'id': showEventId,
      'show_id': showId,
      'season_id': seasonId,
      'event_subtype': eventSubtype,
      'episode_number': episodeNumber,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
    });

    await supabaseClient.from('calendar_events').insert(
          buildShowEventCalendarPayload(
            showEventId: showEventId,
            startDatetime: startDatetime,
            eventSubtype: eventSubtype,
            duration: duration,
          ),
        );
  }

  Future<void> updateCalendarEvent({
    required String calendarEventId,
    DateTime? startDatetime,
    DateTime? endDatetime,
    String? eventType,
    int? dramaLevel,
    String? eventEntityType,
    String? showEventId,
    String? creatorEventId,
    String? trashEventId,
  }) async {
    final payload = <String, dynamic>{
      if (startDatetime != null)
        'start_datetime': _toDatabaseTimestamptz(startDatetime),
      if (endDatetime != null)
        'end_datetime': _toDatabaseTimestamptz(endDatetime),
      if (eventType != null) 'event_type': eventType,
      if (dramaLevel != null) 'drama_level': dramaLevel,
      if (eventEntityType != null) 'event_entity_type': eventEntityType,
      if (showEventId != null) 'show_event_id': showEventId,
      if (creatorEventId != null) 'creator_event_id': creatorEventId,
      if (trashEventId != null) 'trash_event_id': trashEventId,
    };
    if (payload.isEmpty) return;
    await supabaseClient
        .from('calendar_events')
        .update(payload)
        .eq('id', calendarEventId);
  }

  Future<int> createCreatorEventBlockForSeason({
    required String creatorId,
    required String showId,
    required String seasonId,
    required String eventKind,
    String? titlePrefix,
    String? descriptionTemplate,
    Duration? duration,
  }) async {
    final response = await supabaseClient
        .from('calendar_events')
        .select(
            'start_datetime, end_datetime, show_events!inner(episode_number, show_id, season_id)')
        .eq('event_entity_type', 'show_event')
        .eq('show_events.show_id', showId)
        .eq('show_events.season_id', seasonId)
        .order('start_datetime', ascending: true);

    final rows = response as List<dynamic>;
    var created = 0;

    for (final row in rows) {
      final se = row['show_events'] as Map<String, dynamic>?;
      final episodeNumber = se?['episode_number'] as int?;
      final start = DateTime.parse(row['start_datetime'] as String).toUtc();
      final end = row['end_datetime'] != null
          ? DateTime.parse(row['end_datetime'] as String).toUtc()
          : start.add(duration ?? const Duration(hours: 1));
      final creatorEventId = const Uuid().v4();

      await supabaseClient.from('creator_events').insert({
        'id': creatorEventId,
        'creator_id': creatorId,
        'event_kind': eventKind,
        'related_show_id': showId,
        'related_season_id': seasonId,
        'episode_number': episodeNumber,
        'title': titlePrefix != null && episodeNumber != null
            ? '$titlePrefix $episodeNumber'
            : null,
        'description': descriptionTemplate,
      });

      await supabaseClient.from('calendar_events').insert({
        'id': const Uuid().v4(),
        'start_datetime': start.toIso8601String(),
        'end_datetime': end.toIso8601String(),
        'event_type': 'creator',
        'event_entity_type': 'creator_event',
        'creator_event_id': creatorEventId,
      });

      created++;
    }

    return created;
  }

  Future<void> addTrashEvent({
    required String title,
    String? description,
    String? imageUrl,
    String? location,
    String? address,
    String? organizer,
    String? price,
    String? externalUrl,
    String? relatedShowId,
    String? relatedSeasonId,
    required DateTime scheduledAt,
    Duration? duration,
  }) async {
    final trashEventId = const Uuid().v4();
    await supabaseClient.from('trash_events').insert({
      'id': trashEventId,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'location': location,
      'address': address,
      'organizer': organizer,
      'price': price,
      'external_url': externalUrl,
      'related_show_id': relatedShowId,
      'related_season_id': relatedSeasonId,
    });

    final end = scheduledAt.add(duration ?? const Duration(hours: 2));
    await supabaseClient.from('calendar_events').insert({
      'id': const Uuid().v4(),
      'start_datetime': _toDatabaseTimestamptz(scheduledAt),
      'end_datetime': _toDatabaseTimestamptz(end),
      'event_type': 'community',
      'event_entity_type': 'trash_event',
      'trash_event_id': trashEventId,
    });
  }

  Future<int> addTrashEventSeries({
    required String title,
    String? description,
    String? imageUrl,
    String? location,
    String? address,
    String? organizer,
    String? price,
    String? externalUrl,
    String? relatedShowId,
    String? relatedSeasonId,
    required DateTime startAt,
    required int occurrences,
    required Duration interval,
    Duration? eventDuration,
  }) async {
    var created = 0;
    for (var i = 0; i < occurrences; i++) {
      final scheduledAt = startAt.add(interval * i);
      await addTrashEvent(
        title: title,
        description: description,
        imageUrl: imageUrl,
        location: location,
        address: address,
        organizer: organizer,
        price: price,
        externalUrl: externalUrl,
        relatedShowId: relatedShowId,
        relatedSeasonId: relatedSeasonId,
        scheduledAt: scheduledAt,
        duration: eventDuration,
      );
      created++;
    }
    return created;
  }

  Future<void> updateTrashEvent({
    required String trashEventId,
    String? title,
    String? description,
    String? imageUrl,
    String? location,
    String? address,
    String? organizer,
    String? price,
    String? externalUrl,
    String? relatedShowId,
    String? relatedSeasonId,
  }) async {
    final payload = <String, dynamic>{
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      if (location != null) 'location': location,
      if (address != null) 'address': address,
      if (organizer != null) 'organizer': organizer,
      if (price != null) 'price': price,
      if (externalUrl != null) 'external_url': externalUrl,
      if (relatedShowId != null) 'related_show_id': relatedShowId,
      if (relatedSeasonId != null) 'related_season_id': relatedSeasonId,
    };
    if (payload.isEmpty) return;
    await supabaseClient
        .from('trash_events')
        .update(payload)
        .eq('id', trashEventId);
  }

  Future<List<Map<String, dynamic>>> getFeedItems() async {
    final response = await supabaseClient
        .from('feed_items')
        .select('id, item_type, data, feed_timestamp, priority')
        .order('priority', ascending: true)
        .order('feed_timestamp', ascending: false)
        .limit(500);
    return (response as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<int> _nextFeedPriority() async {
    final response = await supabaseClient
        .from('feed_items')
        .select('priority')
        .order('priority', ascending: false)
        .limit(1);
    final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();
    if (rows.isEmpty) return 1;
    final current =
        int.tryParse(rows.first['priority']?.toString() ?? '0') ?? 0;
    return current + 1;
  }

  Future<void> addQuoteOfWeekFeedItem({
    required String quote,
    required String speakerName,
    required String showId,
    required String showTitle,
    int? seasonNumber,
    int? episodeNumber,
    String? ctaLabel,
  }) async {
    final priority = await _nextFeedPriority();
    await supabaseClient.from('feed_items').insert({
      'id': const Uuid().v4(),
      'item_type': 'quote_of_the_week',
      'data': {
        'quote': quote,
        'speaker_name': speakerName,
        'show_id': showId,
        'show_title': showTitle,
        if (seasonNumber != null) 'season_number': seasonNumber,
        if (episodeNumber != null) 'episode_number': episodeNumber,
        if (ctaLabel != null && ctaLabel.trim().isNotEmpty)
          'cta_label': ctaLabel,
      },
      'feed_timestamp': _toDatabaseTimestamptz(DateTime.now()),
      'priority': priority,
    });
  }

  Future<void> addThrowbackFeedItem({
    required String label,
    required String momentText,
    required String showId,
    required String showTitle,
    int? seasonNumber,
    int? episodeNumber,
    String? ctaLabel,
    String? stickerLabel,
  }) async {
    final priority = await _nextFeedPriority();
    await supabaseClient.from('feed_items').insert({
      'id': const Uuid().v4(),
      'item_type': 'throwback_moment',
      'data': {
        'label': label,
        'moment_text': momentText,
        'show_id': showId,
        'show_title': showTitle,
        if (seasonNumber != null) 'season_number': seasonNumber,
        if (episodeNumber != null) 'episode_number': episodeNumber,
        if (ctaLabel != null && ctaLabel.trim().isNotEmpty)
          'cta_label': ctaLabel,
        if (stickerLabel != null && stickerLabel.trim().isNotEmpty)
          'sticker_label': stickerLabel,
      },
      'feed_timestamp': _toDatabaseTimestamptz(DateTime.now()),
      'priority': priority,
    });
  }

  Future<void> updateFeedItem({
    required String feedItemId,
    String? itemType,
    Map<String, dynamic>? data,
    DateTime? feedTimestamp,
    int? priority,
  }) async {
    final payload = <String, dynamic>{
      if (itemType != null && itemType.trim().isNotEmpty) 'item_type': itemType,
      if (data != null) 'data': data,
      if (feedTimestamp != null)
        'feed_timestamp': _toDatabaseTimestamptz(feedTimestamp),
      if (priority != null) 'priority': priority,
    };
    if (payload.isEmpty) return;
    await supabaseClient
        .from('feed_items')
        .update(payload)
        .eq('id', feedItemId);
  }

  Future<void> updateFeedItemPriority({
    required String feedItemId,
    required int priority,
  }) async {
    await supabaseClient
        .from('feed_items')
        .update({'priority': priority}).eq('id', feedItemId);
  }

  Future<List<Map<String, dynamic>>> getNewsTickerItems() async {
    final response = await supabaseClient
        .from('news_ticker_items')
        .select('id, headline, is_active, priority, created_at, updated_at')
        .order('priority', ascending: true)
        .order('updated_at', ascending: false)
        .limit(500);
    return (response as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<int> _nextNewsTickerPriority() async {
    final response = await supabaseClient
        .from('news_ticker_items')
        .select('priority')
        .order('priority', ascending: false)
        .limit(1);
    final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();
    if (rows.isEmpty) return 1;
    final current =
        int.tryParse(rows.first['priority']?.toString() ?? '0') ?? 0;
    return current + 1;
  }

  Future<void> addNewsTickerItem({
    required String headline,
    int? priority,
    bool isActive = true,
  }) async {
    final resolvedPriority = priority ?? await _nextNewsTickerPriority();
    await supabaseClient.from('news_ticker_items').insert({
      'id': const Uuid().v4(),
      'headline': headline,
      'is_active': isActive,
      'priority': resolvedPriority,
    });
  }

  Future<void> updateNewsTickerItem({
    required String newsTickerItemId,
    String? headline,
    int? priority,
    bool? isActive,
  }) async {
    final payload = <String, dynamic>{
      if (headline != null && headline.trim().isNotEmpty) 'headline': headline,
      if (priority != null) 'priority': priority,
      if (isActive != null) 'is_active': isActive,
    };
    if (payload.isEmpty) return;
    await supabaseClient
        .from('news_ticker_items')
        .update(payload)
        .eq('id', newsTickerItemId);
  }

  Future<void> updateNewsTickerItemPriority({
    required String newsTickerItemId,
    required int priority,
  }) async {
    await supabaseClient
        .from('news_ticker_items')
        .update({'priority': priority}).eq('id', newsTickerItemId);
  }

  Future<void> deleteCmsRow({
    required String table,
    required String id,
  }) async {
    bool isMissingSchemaObject(Object error) {
      if (error is! PostgrestException) return false;
      return error.code == '42703' || error.code == '42P01';
    }

    Future<void> tryDeleteWhere(
        String sourceTable, String column, String value) async {
      try {
        await supabaseClient.from(sourceTable).delete().eq(column, value);
      } catch (e) {
        if (isMissingSchemaObject(e)) {
          _logger.w(
              'Skipping optional delete: $sourceTable.$column does not exist in this schema.');
          return;
        }
        rethrow;
      }
    }

    Future<void> tryUpdateWhere(
      String sourceTable,
      Map<String, dynamic> payload,
      String column,
      String value,
    ) async {
      try {
        await supabaseClient
            .from(sourceTable)
            .update(payload)
            .eq(column, value);
      } catch (e) {
        if (isMissingSchemaObject(e)) {
          _logger.w(
              'Skipping optional update: $sourceTable.$column does not exist in this schema.');
          return;
        }
        rethrow;
      }
    }

    Future<List<String>> collectIds(
        String sourceTable, String column, String value) async {
      final rows =
          await supabaseClient.from(sourceTable).select('id').eq(column, value);
      return (rows as List<dynamic>)
          .map((e) => (e as Map<String, dynamic>)['id'] as String?)
          .whereType<String>()
          .toList();
    }

    Future<void> deleteCalendarByRelation(
        String relationColumn, List<String> relationIds) async {
      if (relationIds.isEmpty) return;
      await supabaseClient
          .from('calendar_events')
          .delete()
          .inFilter(relationColumn, relationIds);
    }

    switch (table) {
      case 'shows':
        final showEventIds = await collectIds('show_events', 'show_id', id);
        await deleteCalendarByRelation('show_event_id', showEventIds);

        await supabaseClient.from('show_events').delete().eq('show_id', id);
        await supabaseClient.from('seasons').delete().eq('show_id', id);

        // Remove non-core references that can block show deletion.
        await tryDeleteWhere('user_show_relations', 'show_id', id);
        await tryDeleteWhere('show_social_tags', 'show_id', id);
        await tryDeleteWhere('show_social_videos', 'show_id', id);
        await tryDeleteWhere('feed_items', 'show_id', id);

        // Keep optional references consistent for non-core tables.
        await tryUpdateWhere(
          'creator_events',
          {'related_show_id': null, 'related_season_id': null},
          'related_show_id',
          id,
        );
        await tryUpdateWhere(
          'trash_events',
          {'related_show_id': null, 'related_season_id': null},
          'related_show_id',
          id,
        );
        break;
      case 'seasons':
        final showEventIds = await collectIds('show_events', 'season_id', id);
        await deleteCalendarByRelation('show_event_id', showEventIds);

        await supabaseClient.from('show_events').delete().eq('season_id', id);
        await supabaseClient
            .from('creator_events')
            .update({'related_season_id': null}).eq('related_season_id', id);
        await supabaseClient
            .from('trash_events')
            .update({'related_season_id': null}).eq('related_season_id', id);
        break;
      case 'creators':
        final creatorEventIds =
            await collectIds('creator_events', 'creator_id', id);
        await deleteCalendarByRelation('creator_event_id', creatorEventIds);

        await supabaseClient
            .from('creator_events')
            .delete()
            .eq('creator_id', id);
        await supabaseClient
            .from('user_creator_relations')
            .delete()
            .eq('creator_id', id);
        break;
      case 'show_events':
        await supabaseClient
            .from('calendar_events')
            .delete()
            .eq('show_event_id', id);
        break;
      case 'creator_events':
        await supabaseClient
            .from('calendar_events')
            .delete()
            .eq('creator_event_id', id);
        break;
      case 'trash_events':
        await supabaseClient
            .from('calendar_events')
            .delete()
            .eq('trash_event_id', id);
        break;
      default:
        break;
    }

    await supabaseClient.from(table).delete().eq('id', id);
  }
}
