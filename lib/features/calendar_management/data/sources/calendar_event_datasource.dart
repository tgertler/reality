import 'package:frontend/features/calendar_management/domain/entities/resolved_calendar_event.dart';
import 'package:frontend/features/calendar_management/domain/entities/season.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/logger.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/entities/calendar_event_with_show.dart';
import '../../domain/entities/show.dart';

class CalendarEventDataSource {
  final SupabaseClient supabaseClient;
  final Logger _logger = getLogger('CalendarEventDataSource');

  CalendarEventDataSource(this.supabaseClient);

  /// Maps a raw Supabase row / RPC row to a [CalendarEvent].
  /// Handles both direct table columns and embedded show_events join.
  CalendarEvent _mapCalendarEvent(Map<String, dynamic> e) {
    final showEvent = e['show_events'] as Map<String, dynamic>?;
    final start = _parseDateTimeValue(e['start_datetime']) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final end = _parseDateTimeValue(e['end_datetime']) ??
        start.add(const Duration(hours: 1));

    return CalendarEvent(
      calendarEventId:
          e['id']?.toString() ?? e['calendar_event_id']?.toString() ?? '',
      showId: e['show_id']?.toString() ?? '',
      seasonId: e['season_id']?.toString(),
      startDatetime: start,
      endDatetime: end,
      dramaLevel: _asInt(e['drama_level']),
      eventEntityType: e['event_entity_type']?.toString(),
      showEventId: e['show_event_id']?.toString(),
      creatorEventId: e['creator_event_id']?.toString(),
      trashEventId: e['trash_event_id']?.toString(),
      episodeNumber: _asInt(showEvent?['episode_number']),
      eventSubtype: showEvent?['event_subtype']?.toString(),
    );
  }

  Future<List<CalendarEvent>> getCalendarEventsByDate(DateTime date) async {
    final dateStartLocal = DateTime(date.year, date.month, date.day);
    final dateStart = dateStartLocal.toUtc();
    final dateEnd = dateStart.add(const Duration(days: 1));

    final response = await supabaseClient
        .from('calendar_events')
        .select('*, show_events(episode_number, event_subtype)')
        .eq('event_entity_type', 'show_event')
        .gte('start_datetime', dateStart.toIso8601String())
        .lt('start_datetime', dateEnd.toIso8601String());

    final results = response as List<dynamic>;

    return results
        .map((event) => _mapCalendarEvent(event as Map<String, dynamic>))
        .toList();
  }

  Future<CalendarEvent> getCalendarEventById(String id) async {
    final response = await supabaseClient
        .from('calendar_events')
        .select('*, show_events(episode_number, event_subtype)')
        .eq('id', id)
        .single();

    return _mapCalendarEvent(response);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // OLD RPC-based method — commented out, replaced by:
  //   • getCalendarEventsWithShowsByDateDirect  (backward-compat, no RPC)
  //   • getResolvedCalendarEventsByDate         (new view-based calendar)
  // ──────────────────────────────────────────────────────────────────────────
  // Future<List<CalendarEventWithShow>> getCalendarEventsWithShowsByDate(
  //     DateTime date, List<String> showIds, List<String> attendeeIds) async {
  //   _logger.i(
  //       'Fetching calendar events with shows for date: $date, showIds: $showIds, attendeeIds: $attendeeIds');
  //   final response = await supabaseClient
  //       .rpc('get_calendar_events_with_shows_by_date', params: {
  //     'event_date': date.toIso8601String(),
  //     'attendee_ids': attendeeIds,
  //     'show_ids': showIds,
  //   });
  //   final results = response as List<dynamic>;
  //   _logger.i(
  //       'Fetched ${results.length} calendar events with shows for date: $date');
  //   return results
  //       .map((event) => CalendarEventWithShow(
  //             calendarEvent: CalendarEvent(
  //               calendarEventId: event['calendar_event_id'].toString(),
  //               showId: event['show_id'].toString(),
  //               seasonId: event['season_id'].toString(),
  //               startDatetime: DateTime.parse(event['start_datetime']),
  //               endDatetime: DateTime.parse(event['end_datetime']),
  //               dramaLevel: event['drama_level'],
  //               eventEntityType: event['event_entity_type'] as String?,
  //               showEventId: event['show_event_id'] as String?,
  //               creatorEventId: event['creator_event_id'] as String?,
  //               trashEventId: event['trash_event_id'] as String?,
  //               episodeNumber: event['episode_number'] as int?,
  //               eventSubtype: event['event_subtype'] as String?,
  //             ),
  //             show: Show(
  //               showId: event['show_id'].toString(),
  //               title: event['show_title'],
  //             ),
  //             season: Season(
  //               seasonId: event['season_id'].toString(),
  //               showId: event['show_id'].toString(),
  //               seasonNumber: event['season_number'],
  //               totalEpisodes: event['total_episodes'],
  //               streamingOption: event['streaming_option'],
  //             ),
  //           ))
  //       .toList();
  // }

  /// Direct-query replacement for the old RPC — used by the home page
  /// to show which shows are airing today (show_events only).
  ///
  /// NOTE: In the new schema, show_id / season_id live on show_events, not
  /// directly on calendar_events, so we join through show_events.
  Future<List<CalendarEventWithShow>> getCalendarEventsWithShowsByDateDirect(
      DateTime date, List<String> showIds, List<String> attendeeIds) async {
    final dateStartLocal = DateTime(date.year, date.month, date.day);
    final dateStart = dateStartLocal.toUtc();
    final dateEnd = dateStart.add(const Duration(days: 1));

    _logger.i('Fetching show events for $dateStart (direct query)');

    final response = await supabaseClient
        .from('calendar_events')
        .select(
          '*, show_events(show_id, season_id, episode_number, event_subtype, shows(title, short_title), seasons(season_number, total_episodes, streaming_option))',
        )
        .eq('event_entity_type', 'show_event')
        .gte('start_datetime', dateStart.toIso8601String())
        .lt('start_datetime', dateEnd.toIso8601String())
        .order('start_datetime', ascending: true);

    final results = response as List<dynamic>;
    _logger.i('Fetched ${results.length} show events for $dateStart');

    final filtered = showIds.isEmpty
        ? results
        : results.where((e) {
            final se = e['show_events'] as Map<String, dynamic>?;
            return showIds.contains(se?['show_id']?.toString());
          }).toList();

    return filtered.map((e) {
      final event = e as Map<String, dynamic>;
      final se = event['show_events'] as Map<String, dynamic>?;
      final showId = se?['show_id']?.toString() ?? '';
      final seasonId = se?['season_id']?.toString() ?? '';
      return CalendarEventWithShow(
        calendarEvent: CalendarEvent(
          calendarEventId: event['id']?.toString() ?? '',
          showId: showId,
          seasonId: seasonId,
          startDatetime: _parseDateTimeValue(event['start_datetime']) ??
              DateTime.fromMillisecondsSinceEpoch(0),
          endDatetime: _parseDateTimeValue(event['end_datetime']) ??
              DateTime.fromMillisecondsSinceEpoch(0),
          dramaLevel: event['drama_level'] as int?,
          eventEntityType: event['event_entity_type'] as String?,
          showEventId: event['show_event_id'] as String?,
          creatorEventId: event['creator_event_id'] as String?,
          trashEventId: event['trash_event_id'] as String?,
          episodeNumber: se?['episode_number'] as int?,
          eventSubtype: se?['event_subtype'] as String?,
        ),
        show: Show(
          showId: showId,
          title: se?['shows']?['title'] as String? ?? '',
          shortTitle: se?['shows']?['short_title'] as String?,
        ),
        season: Season(
          seasonId: seasonId,
          showId: showId,
          seasonNumber: se?['seasons']?['season_number'] as int? ?? 0,
          totalEpisodes: se?['seasons']?['total_episodes'] as int? ?? 0,
          streamingOption: se?['seasons']?['streaming_option'] as String? ?? '',
        ),
      );
    }).toList();
  }

  // ── NEW: view-based helper ─────────────────────────────────────────────────

  /// Maps a flat row from the `calendar_event_resolved` view.
  ResolvedCalendarEvent _mapResolvedCalendarEvent(Map<String, dynamic> e) {
    return CalendarEventDataSource.mapResolvedRowToResolvedCalendarEvent(e);
  }

  static ResolvedCalendarEvent mapResolvedRowToResolvedCalendarEvent(
    Map<String, dynamic> e,
  ) {
    final start = _parseDateTimeValue(e['start_datetime']) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final end = _parseDateTimeValue(e['end_datetime']) ??
        start.add(const Duration(hours: 1));

    return ResolvedCalendarEvent(
      calendarEventId: e['calendar_event_id']?.toString() ?? '',
      startDatetime: start,
      endDatetime: end,
      isShowEvent: e['is_show_event'] as bool? ?? false,
      isCreatorEvent: e['is_creator_event'] as bool? ?? false,
      isTrashEvent: e['is_trash_event'] as bool? ?? false,
      showEventId: e['show_event_id']?.toString(),
      showEventSubtype: e['show_event_subtype']?.toString(),
      showEventEpisodeNumber: _asInt(e['show_event_episode_number']),
      showEventDescription: e['show_event_description']?.toString(),
      showEventShowId: e['show_event_show_id']?.toString(),
      showEventSeasonId: e['show_event_season_id']?.toString(),
      showEventShowTitle: e['show_event_show_title']?.toString(),
      showEventShowShortTitle: e['show_event_show_short_title']?.toString(),
      showEventShowDescription: e['show_event_show_description']?.toString(),
      showEventGenre: e['show_event_genre']?.toString(),
      showEventStreamingOption: e['show_event_streaming_option']?.toString(),
      showEventSeasonNumber: _asInt(e['show_event_season_number']),
      creatorId: e['creator_id']?.toString(),
      creatorEventId: e['creator_event_id']?.toString(),
      creatorEventKind: e['creator_event_kind']?.toString(),
      creatorEventYoutubeUrl: e['creator_event_youtube_url']?.toString(),
      creatorEventThumbnailUrl: e['creator_event_thumbnail_url']?.toString(),
      creatorEventEpisodeNumber: _asInt(e['creator_event_episode_number']),
      creatorEventTitle: e['creator_event_title']?.toString(),
      creatorEventDescription: e['creator_event_description']?.toString(),
      creatorName: e['creator_name']?.toString(),
      creatorAvatarUrl: e['creator_avatar_url']?.toString(),
      creatorYoutubeChannelUrl: e['creator_youtube_channel_url']?.toString(),
      creatorInstagramUrl: e['creator_instagram_url']?.toString(),
      creatorTiktokUrl: e['creator_tiktok_url']?.toString(),
      creatorRelatedShowId: e['creator_related_show_id']?.toString(),
      creatorRelatedSeasonId: e['creator_related_season_id']?.toString(),
      trashEventId: e['trash_event_id']?.toString(),
      trashEventTitle: e['trash_event_title']?.toString(),
      trashEventDescription: e['trash_event_description']?.toString(),
      trashEventImageUrl: e['trash_event_image_url']?.toString(),
      trashEventLocation: e['trash_event_location']?.toString(),
      trashEventAddress: e['trash_event_address']?.toString(),
      trashEventOrganizer: e['trash_event_organizer']?.toString(),
      trashEventPrice: e['trash_event_price']?.toString(),
      trashEventExternalUrl: e['trash_event_external_url']?.toString(),
      trashRelatedShowId: e['trash_related_show_id']?.toString(),
      trashRelatedSeasonId: e['trash_related_season_id']?.toString(),
    );
  }

  /// Queries the `calendar_event_resolved` view for ALL event types
  /// (show_events, creator_events, trash_events) on a given day.
  Future<List<ResolvedCalendarEvent>> getResolvedCalendarEventsByDate(
      DateTime date) async {
    final dateStartLocal = DateTime(date.year, date.month, date.day);
    final dateStart = dateStartLocal.toUtc();
    final dateEnd = dateStart.add(const Duration(days: 1));
    _logger.i('Fetching resolved calendar events for $dateStartLocal (view)');

    final response = await supabaseClient
        .from('calendar_event_resolved')
        .select()
        .gte('start_datetime', dateStart.toIso8601String())
        .lt('start_datetime', dateEnd.toIso8601String())
        .order('start_datetime', ascending: true);

    final results = response as List<dynamic>;
    _logger
        .i('Fetched ${results.length} resolved calendar events for $dateStart');
    return results
        .map((e) => _mapResolvedCalendarEvent(e as Map<String, dynamic>))
        .toList();
  }

  /// Converts a flat view row to [CalendarEventWithShow].
  CalendarEventWithShow _resolvedRowToCalendarEventWithShow(
      Map<String, dynamic> e) {
    return CalendarEventDataSource.mapResolvedRowToCalendarEventWithShow(e);
  }

  static CalendarEventWithShow mapResolvedRowToCalendarEventWithShow(
    Map<String, dynamic> e,
  ) {
    final showId = e['show_event_show_id']?.toString() ?? '';
    final seasonId = e['show_event_season_id']?.toString() ?? '';
    final start = _parseDateTimeValue(e['start_datetime']) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final end = _parseDateTimeValue(e['end_datetime']) ??
        start.add(const Duration(hours: 1));

    return CalendarEventWithShow(
      calendarEvent: CalendarEvent(
        calendarEventId: e['calendar_event_id']?.toString() ?? '',
        showId: showId,
        seasonId: seasonId,
        startDatetime: start,
        endDatetime: end,
        dramaLevel: _asInt(e['drama_level']),
        eventEntityType: 'show_event',
        showEventId: e['show_event_id']?.toString(),
        episodeNumber: _asInt(e['show_event_episode_number']),
        eventSubtype: e['show_event_subtype']?.toString(),
      ),
      show: Show(
        showId: showId,
        title: e['show_event_show_title']?.toString() ?? '',
        shortTitle: e['show_event_show_short_title']?.toString(),
      ),
      season: Season(
        seasonId: seasonId,
        showId: showId,
        seasonNumber: _asInt(e['show_event_season_number']) ?? 0,
        totalEpisodes: 0,
        streamingOption: e['show_event_streaming_option']?.toString() ?? '',
      ),
    );
  }

  static DateTime? _parseDateTimeValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Future<List<CalendarEventWithShow>> getNextThreePremieres() async {
    _logger.i('Fetching next three premieres (via view)');
    final response = await supabaseClient
        .from('calendar_event_resolved')
        .select()
        .eq('is_show_event', true)
        .eq('show_event_subtype', 'premiere')
        .gte('start_datetime', DateTime.now().toUtc().toIso8601String())
        .order('start_datetime', ascending: true)
        .limit(3);

    final results = response as List<dynamic>;
    return results
        .map((e) =>
            _resolvedRowToCalendarEventWithShow(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CalendarEventWithShow>> getLastThreePremieres() async {
    _logger.i('Fetching last three premieres (via view)');
    final response = await supabaseClient
        .from('calendar_event_resolved')
        .select()
        .eq('is_show_event', true)
        .eq('show_event_subtype', 'premiere')
        .lte('start_datetime', DateTime.now().toUtc().toIso8601String())
        .order('start_datetime', ascending: false)
        .limit(3);

    final results = response as List<dynamic>;
    return results
        .map((e) =>
            _resolvedRowToCalendarEventWithShow(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CalendarEventWithShow>> getUpcomingCalendarEventsForShow(
      String showId) async {
    _logger.i('Fetching show overview events for show $showId (via view)');

    final response = await supabaseClient
        .from('calendar_event_resolved')
        .select()
        .eq('is_show_event', true)
        .eq('show_event_show_id', showId)
        .order('start_datetime', ascending: true);

    final results = response as List<dynamic>;
    final mapped = results
        .map((e) =>
            _resolvedRowToCalendarEventWithShow(e as Map<String, dynamic>))
        .toList();

    _logger.i('Fetched ${mapped.length} show overview events for show $showId');
    return mapped;
  }

  /// Holt das nächste einzelne Calendar Event für eine Show (nächstes start_datetime >= jetzt)
  Future<CalendarEventWithShow?> getNextCalendarEventForShow(
      String showId) async {
    final nowUtc = DateTime.now().toUtc();
    final nowLocal = DateTime.now();
    final startOfTodayUtc =
        DateTime(nowLocal.year, nowLocal.month, nowLocal.day).toUtc();
    final startOfTomorrowUtc = startOfTodayUtc.add(const Duration(days: 1));
    _logger.i('Fetching next calendar event for show $showId (via view)');

    // If there is an event on today's date, show it in the "Nächstes Event" card.
    final todayEvents = await supabaseClient
        .from('calendar_event_resolved')
        .select()
        .eq('is_show_event', true)
        .eq('show_event_show_id', showId)
        .gte('start_datetime', startOfTodayUtc.toIso8601String())
        .lt('start_datetime', startOfTomorrowUtc.toIso8601String())
        .order('start_datetime', ascending: true);

    final todayList = todayEvents as List<dynamic>;
    if (todayList.isNotEmpty) {
      final todayRow = todayList.first as Map<String, dynamic>;
      _logger.i('Using today event: ${todayRow['calendar_event_id']}');
      return _resolvedRowToCalendarEventWithShow(todayRow);
    }

    final response = await supabaseClient
        .from('calendar_event_resolved')
        .select()
        .eq('is_show_event', true)
        .eq('show_event_show_id', showId)
        .gte('start_datetime', nowUtc.toIso8601String())
        .order('start_datetime', ascending: true)
        .limit(1)
        .maybeSingle();

    if (response == null) {
      _logger.i('No upcoming event found for show $showId');
      return null;
    }

    _logger.i('Fetched next event: ${response['calendar_event_id']}');
    return _resolvedRowToCalendarEventWithShow(response);
  }
}
