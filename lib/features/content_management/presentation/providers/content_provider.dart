import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/supabase_provider.dart';
import 'package:logger/logger.dart';
import '../../../../core/utils/logger.dart';
import '../../data/repositories/content_repository_impl.dart';
import '../../data/sources/content_data_source.dart';
import '../../domain/entities/show.dart';
import '../../domain/entities/season.dart';
import '../../domain/entities/attendee.dart';
import '../../domain/use_cases/add_show.dart';
import '../../domain/use_cases/add_season.dart';
import '../../domain/use_cases/add_attendee.dart';
import '../../domain/use_cases/generate_calendar_events.dart';

class ContentState {
  final bool isLoading;
  final String errorMessage;
  final String successMessage;
  final List<Show> availableShows;
  final List<Season> availableSeasons;
  final List<Map<String, dynamic>> availableCreators;
  final List<Season> allSeasons;
  final List<Map<String, dynamic>> creatorEvents;
  final List<Map<String, dynamic>> trashEvents;
  final List<Map<String, dynamic>> showsTableRows;
  final List<Map<String, dynamic>> seasonsTableRows;
  final List<Map<String, dynamic>> showEventsTableRows;
  final List<Map<String, dynamic>> calendarEventsTableRows;
  final List<Map<String, dynamic>> feedItems;
  final List<Map<String, dynamic>> newsTickerItems;

  ContentState({
    this.isLoading = false,
    this.errorMessage = '',
    this.successMessage = '',
    this.availableShows = const [],
    this.availableSeasons = const [],
    this.availableCreators = const [],
    this.allSeasons = const [],
    this.creatorEvents = const [],
    this.trashEvents = const [],
    this.showsTableRows = const [],
    this.seasonsTableRows = const [],
    this.showEventsTableRows = const [],
    this.calendarEventsTableRows = const [],
    this.feedItems = const [],
    this.newsTickerItems = const [],
  });

  ContentState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    List<Show>? availableShows,
    List<Season>? availableSeasons,
    List<Map<String, dynamic>>? availableCreators,
    List<Season>? allSeasons,
    List<Map<String, dynamic>>? creatorEvents,
    List<Map<String, dynamic>>? trashEvents,
    List<Map<String, dynamic>>? showsTableRows,
    List<Map<String, dynamic>>? seasonsTableRows,
    List<Map<String, dynamic>>? showEventsTableRows,
    List<Map<String, dynamic>>? calendarEventsTableRows,
    List<Map<String, dynamic>>? feedItems,
    List<Map<String, dynamic>>? newsTickerItems,
  }) {
    return ContentState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      availableShows: availableShows ?? this.availableShows,
      availableSeasons: availableSeasons ?? this.availableSeasons,
      availableCreators: availableCreators ?? this.availableCreators,
      allSeasons: allSeasons ?? this.allSeasons,
      creatorEvents: creatorEvents ?? this.creatorEvents,
      trashEvents: trashEvents ?? this.trashEvents,
      showsTableRows: showsTableRows ?? this.showsTableRows,
      seasonsTableRows: seasonsTableRows ?? this.seasonsTableRows,
      showEventsTableRows: showEventsTableRows ?? this.showEventsTableRows,
      calendarEventsTableRows:
          calendarEventsTableRows ?? this.calendarEventsTableRows,
      feedItems: feedItems ?? this.feedItems,
      newsTickerItems: newsTickerItems ?? this.newsTickerItems,
    );
  }
}

class ContentNotifier extends StateNotifier<ContentState> {
  final ContentRepositoryImpl repository;
  final AddShow addShowUseCase;
  final AddSeason addSeasonUseCase;
  final AddAttendee addAttendeeUseCase;
  final GenerateCalendarEvents generateCalendarEventsUseCase;
  final Logger _logger = getLogger('ContentNotifier');

  ContentNotifier(
    this.repository,
    this.addShowUseCase,
    this.addSeasonUseCase,
    this.addAttendeeUseCase,
    this.generateCalendarEventsUseCase,
  ) : super(ContentState());

  void clearMessages() {
    state = state.copyWith(errorMessage: '', successMessage: '');
  }

  Future<void> addShow(Show show) async {
    _logger.i('Adding show: $show');
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      await addShowUseCase.call(show);
      _logger.i('Show added successfully');
      state = state.copyWith(isLoading: false, successMessage: 'Show angelegt');
      await loadShows();
    } catch (e, stackTrace) {
      _logger.e('Error adding show', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> addSeason(Season season) async {
    _logger.i('Adding season: $season');
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      await addSeasonUseCase.call(season);
      _logger.i('Season added successfully');
      state =
          state.copyWith(isLoading: false, successMessage: 'Staffel angelegt');
      if (season.showId != null) {
        await loadSeasonsForShow(season.showId!);
      }
      await loadAllSeasons();
    } catch (e, stackTrace) {
      _logger.e('Error adding season', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadAllSeasons() async {
    try {
      final seasons = await repository.getAllSeasons();
      state = state.copyWith(allSeasons: seasons);
    } catch (e, stackTrace) {
      _logger.e('Error loading all seasons', e, stackTrace);
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> loadCreatorEvents() async {
    try {
      final events = await repository.getCreatorEvents();
      state = state.copyWith(creatorEvents: events);
    } catch (e, stackTrace) {
      _logger.e('Error loading creator events', e, stackTrace);
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> loadTrashEvents() async {
    try {
      final events = await repository.getTrashEvents();
      state = state.copyWith(trashEvents: events);
    } catch (e, stackTrace) {
      _logger.e('Error loading trash events', e, stackTrace);
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> loadShowsTableRows() async {
    try {
      final rows = await repository.getShowsTableRows();
      state = state.copyWith(showsTableRows: rows);
    } catch (e, stackTrace) {
      _logger.e('Error loading show table rows', e, stackTrace);
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> loadSeasonsTableRowsByShowId(String showId) async {
    try {
      final rows = await repository.getSeasonsTableRowsByShowId(showId);
      state = state.copyWith(seasonsTableRows: rows);
    } catch (e, stackTrace) {
      _logger.e('Error loading season table rows', e, stackTrace);
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> loadShowEventsBySeasonId(String seasonId) async {
    try {
      final rows = await repository.getShowEventsBySeasonId(seasonId);
      state = state.copyWith(showEventsTableRows: rows);
    } catch (e, stackTrace) {
      _logger.e('Error loading show events by season', e, stackTrace);
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> loadCalendarEventsByShowEventId(String showEventId) async {
    try {
      final rows = await repository.getCalendarEventsByShowEventId(showEventId);
      state = state.copyWith(calendarEventsTableRows: rows);
    } catch (e, stackTrace) {
      _logger.e('Error loading calendar events by show event', e, stackTrace);
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> loadFeedItems() async {
    try {
      final items = await repository.getFeedItems();
      state = state.copyWith(feedItems: items);
    } catch (e, stackTrace) {
      _logger.e('Error loading feed items', e, stackTrace);
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> loadNewsTickerItems() async {
    try {
      final items = await repository.getNewsTickerItems();
      state = state.copyWith(newsTickerItems: items);
    } catch (e, stackTrace) {
      _logger.e('Error loading news ticker items', e, stackTrace);
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void clearShowDrilldown() {
    state = state.copyWith(
      seasonsTableRows: const [],
      showEventsTableRows: const [],
      calendarEventsTableRows: const [],
    );
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
    state =
        state.copyWith(isLoading: true, errorMessage: '', successMessage: '');
    try {
      await repository.updateShow(
        showId: showId,
        title: title,
        shortTitle: shortTitle,
        description: description,
        genre: genre,
        releaseWindow: releaseWindow,
        status: status,
        slug: slug,
        tmdbId: tmdbId,
        traktSlug: traktSlug,
        headerImageUrl: headerImageUrl,
        mainColor: mainColor,
      );
      await loadShows();
      await loadShowsTableRows();
      state =
          state.copyWith(isLoading: false, successMessage: 'Show aktualisiert');
    } catch (e, stackTrace) {
      _logger.e('Error updating show', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
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
    state =
        state.copyWith(isLoading: true, errorMessage: '', successMessage: '');
    try {
      await repository.updateSeason(
        seasonId: seasonId,
        showId: showId,
        seasonNumber: seasonNumber,
        totalEpisodes: totalEpisodes,
        releaseFrequency: releaseFrequency,
        startDate: startDate,
        streamingReleaseTime: streamingReleaseTime,
        episodeLength: episodeLength,
        streamingOption: streamingOption,
        status: status,
      );
      await loadAllSeasons();
      state = state.copyWith(
          isLoading: false, successMessage: 'Staffel aktualisiert');
    } catch (e, stackTrace) {
      _logger.e('Error updating season', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> addAttendee(Attendee attendee) async {
    _logger.i('Adding attendee: $attendee');
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      await addAttendeeUseCase.call(attendee);
      _logger.i('Attendee added successfully');
      state = state.copyWith(isLoading: false);
    } catch (e, stackTrace) {
      _logger.e('Error adding attendee', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadShows() async {
    try {
      final shows = await repository.getShows();
      state = state.copyWith(availableShows: shows);
    } catch (e, stackTrace) {
      _logger.e('Error loading shows', e, stackTrace);
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> loadSeasonsForShow(String showId) async {
    try {
      final seasons = await repository.getSeasonsByShowId(showId);
      state = state.copyWith(availableSeasons: seasons);
    } catch (e, stackTrace) {
      _logger.e('Error loading seasons', e, stackTrace);
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<List<Season>> getSeasonsByShowIdDirect(String showId) async {
    return repository.getSeasonsByShowId(showId);
  }

  Future<void> loadCreators() async {
    try {
      final creators = await repository.getCreators();
      state = state.copyWith(availableCreators: creators);
    } catch (e, stackTrace) {
      _logger.e('Error loading creators', e, stackTrace);
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  Future<void> addCreator({
    required String name,
    String? description,
    String? avatarUrl,
    String? youtubeChannelUrl,
    String? instagramUrl,
    String? tiktokUrl,
  }) async {
    state =
        state.copyWith(isLoading: true, errorMessage: '', successMessage: '');
    try {
      await repository.addCreator(
        name: name,
        description: description,
        avatarUrl: avatarUrl,
        youtubeChannelUrl: youtubeChannelUrl,
        instagramUrl: instagramUrl,
        tiktokUrl: tiktokUrl,
      );
      await loadCreators();
      state =
          state.copyWith(isLoading: false, successMessage: 'Creator angelegt');
    } catch (e, stackTrace) {
      _logger.e('Error adding creator', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
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
    state =
        state.copyWith(isLoading: true, errorMessage: '', successMessage: '');
    try {
      await repository.updateCreator(
        creatorId: creatorId,
        name: name,
        description: description,
        avatarUrl: avatarUrl,
        youtubeChannelUrl: youtubeChannelUrl,
        instagramUrl: instagramUrl,
        tiktokUrl: tiktokUrl,
      );
      await loadCreators();
      state = state.copyWith(
          isLoading: false, successMessage: 'Creator aktualisiert');
    } catch (e, stackTrace) {
      _logger.e('Error updating creator', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
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
    state =
        state.copyWith(isLoading: true, errorMessage: '', successMessage: '');
    try {
      await repository.addCreatorEvent(
        creatorId: creatorId,
        eventKind: eventKind,
        relatedShowId: relatedShowId,
        relatedSeasonId: relatedSeasonId,
        episodeNumber: episodeNumber,
        title: title,
        description: description,
        youtubeUrl: youtubeUrl,
        thumbnailUrl: thumbnailUrl,
        scheduledAt: scheduledAt,
        duration: duration,
      );
      await loadCreatorEvents();
      state = state.copyWith(
          isLoading: false, successMessage: 'Creator Event angelegt');
    } catch (e, stackTrace) {
      _logger.e('Error adding creator event', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
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
    state =
        state.copyWith(isLoading: true, errorMessage: '', successMessage: '');
    try {
      await repository.updateCreatorEvent(
        creatorEventId: creatorEventId,
        creatorId: creatorId,
        eventKind: eventKind,
        relatedShowId: relatedShowId,
        relatedSeasonId: relatedSeasonId,
        episodeNumber: episodeNumber,
        title: title,
        description: description,
        youtubeUrl: youtubeUrl,
        thumbnailUrl: thumbnailUrl,
      );
      await loadCreatorEvents();
      state = state.copyWith(
          isLoading: false, successMessage: 'Creator Event aktualisiert');
    } catch (e, stackTrace) {
      _logger.e('Error updating creator event', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> updateShowEvent({
    required String showEventId,
    String? showId,
    String? seasonId,
    String? eventSubtype,
    int? episodeNumber,
    String? description,
  }) async {
    state =
        state.copyWith(isLoading: true, errorMessage: '', successMessage: '');
    try {
      await repository.updateShowEvent(
        showEventId: showEventId,
        showId: showId,
        seasonId: seasonId,
        eventSubtype: eventSubtype,
        episodeNumber: episodeNumber,
        description: description,
      );
      state = state.copyWith(
          isLoading: false, successMessage: 'Show Event aktualisiert');
    } catch (e, stackTrace) {
      _logger.e('Error updating show event', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
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
    state =
        state.copyWith(isLoading: true, errorMessage: '', successMessage: '');
    try {
      await repository.addShowEventWithCalendarEvent(
        showId: showId,
        seasonId: seasonId,
        eventSubtype: eventSubtype,
        episodeNumber: episodeNumber,
        description: description,
        startDatetime: startDatetime,
        duration: duration,
      );
      state = state.copyWith(
          isLoading: false,
          successMessage: 'Show Event + Calendar Event angelegt');
    } catch (e, stackTrace) {
      _logger.e('Error adding show event with calendar event', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
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
    state =
        state.copyWith(isLoading: true, errorMessage: '', successMessage: '');
    try {
      await repository.updateCalendarEvent(
        calendarEventId: calendarEventId,
        startDatetime: startDatetime,
        endDatetime: endDatetime,
        eventType: eventType,
        dramaLevel: dramaLevel,
        eventEntityType: eventEntityType,
        showEventId: showEventId,
        creatorEventId: creatorEventId,
        trashEventId: trashEventId,
      );
      state = state.copyWith(
          isLoading: false, successMessage: 'Calendar Event aktualisiert');
    } catch (e, stackTrace) {
      _logger.e('Error updating calendar event', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> createCreatorEventBlockForSeason({
    required String creatorId,
    required String showId,
    required String seasonId,
    required String eventKind,
    String? titlePrefix,
    String? descriptionTemplate,
  }) async {
    state =
        state.copyWith(isLoading: true, errorMessage: '', successMessage: '');
    try {
      final created = await repository.createCreatorEventBlockForSeason(
        creatorId: creatorId,
        showId: showId,
        seasonId: seasonId,
        eventKind: eventKind,
        titlePrefix: titlePrefix,
        descriptionTemplate: descriptionTemplate,
      );
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Block angelegt: $created Events',
      );
    } catch (e, stackTrace) {
      _logger.e('Error creating creator event block', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
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
  }) async {
    state =
        state.copyWith(isLoading: true, errorMessage: '', successMessage: '');
    try {
      await repository.addTrashEvent(
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
      );
      await loadTrashEvents();
      state = state.copyWith(
          isLoading: false, successMessage: 'Trash Event angelegt');
    } catch (e, stackTrace) {
      _logger.e('Error adding trash event', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> addTrashEventSeries({
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
    state =
        state.copyWith(isLoading: true, errorMessage: '', successMessage: '');
    try {
      final created = await repository.addTrashEventSeries(
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
        startAt: startAt,
        occurrences: occurrences,
        interval: interval,
        eventDuration: eventDuration,
      );
      await loadTrashEvents();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Trash-Serie angelegt: $created Termine',
      );
    } catch (e, stackTrace) {
      _logger.e('Error creating trash event series', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
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
    state =
        state.copyWith(isLoading: true, errorMessage: '', successMessage: '');
    try {
      await repository.updateTrashEvent(
        trashEventId: trashEventId,
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
      );
      await loadTrashEvents();
      state = state.copyWith(
          isLoading: false, successMessage: 'Trash Event aktualisiert');
    } catch (e, stackTrace) {
      _logger.e('Error updating trash event', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
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
    state =
        state.copyWith(isLoading: true, errorMessage: '', successMessage: '');
    try {
      await repository.addQuoteOfWeekFeedItem(
        quote: quote,
        speakerName: speakerName,
        showId: showId,
        showTitle: showTitle,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
        ctaLabel: ctaLabel,
      );
      await loadFeedItems();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Spruch der Woche angelegt',
      );
    } catch (e, stackTrace) {
      _logger.e('Error adding quote feed item', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
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
    state =
        state.copyWith(isLoading: true, errorMessage: '', successMessage: '');
    try {
      await repository.addThrowbackFeedItem(
        label: label,
        momentText: momentText,
        showId: showId,
        showTitle: showTitle,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
        ctaLabel: ctaLabel,
        stickerLabel: stickerLabel,
      );
      await loadFeedItems();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Throwback angelegt',
      );
    } catch (e, stackTrace) {
      _logger.e('Error adding throwback feed item', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> updateFeedItem({
    required String feedItemId,
    String? itemType,
    Map<String, dynamic>? data,
    DateTime? feedTimestamp,
    int? priority,
  }) async {
    state =
        state.copyWith(isLoading: true, errorMessage: '', successMessage: '');
    try {
      await repository.updateFeedItem(
        feedItemId: feedItemId,
        itemType: itemType,
        data: data,
        feedTimestamp: feedTimestamp,
        priority: priority,
      );
      await loadFeedItems();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Feed-Item aktualisiert',
      );
    } catch (e, stackTrace) {
      _logger.e('Error updating feed item', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> moveFeedItem({
    required String feedItemId,
    required bool moveUp,
  }) async {
    final current = [...state.feedItems]
      ..sort((a, b) {
        final ap = int.tryParse(a['priority']?.toString() ?? '0') ?? 0;
        final bp = int.tryParse(b['priority']?.toString() ?? '0') ?? 0;
        return ap.compareTo(bp);
      });

    final idx = current.indexWhere((e) => e['id'] == feedItemId);
    if (idx < 0) return;
    final targetIdx = moveUp ? idx - 1 : idx + 1;
    if (targetIdx < 0 || targetIdx >= current.length) return;

    final currentItem = current[idx];
    final targetItem = current[targetIdx];
    final currentPriority =
        int.tryParse(currentItem['priority']?.toString() ?? '0') ?? 0;
    final targetPriority =
        int.tryParse(targetItem['priority']?.toString() ?? '0') ?? 0;

    state =
        state.copyWith(isLoading: true, errorMessage: '', successMessage: '');
    try {
      await repository.updateFeedItemPriority(
        feedItemId: currentItem['id'] as String,
        priority: targetPriority,
      );
      await repository.updateFeedItemPriority(
        feedItemId: targetItem['id'] as String,
        priority: currentPriority,
      );
      await loadFeedItems();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Feed-Reihenfolge aktualisiert',
      );
    } catch (e, stackTrace) {
      _logger.e('Error moving feed item', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> addNewsTickerItem({
    required String headline,
    int? priority,
    bool isActive = true,
  }) async {
    state =
        state.copyWith(isLoading: true, errorMessage: '', successMessage: '');
    try {
      await repository.addNewsTickerItem(
        headline: headline,
        priority: priority,
        isActive: isActive,
      );
      await loadNewsTickerItems();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Newsticker-Eintrag angelegt',
      );
    } catch (e, stackTrace) {
      _logger.e('Error adding news ticker item', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> updateNewsTickerItem({
    required String newsTickerItemId,
    String? headline,
    int? priority,
    bool? isActive,
  }) async {
    state =
        state.copyWith(isLoading: true, errorMessage: '', successMessage: '');
    try {
      await repository.updateNewsTickerItem(
        newsTickerItemId: newsTickerItemId,
        headline: headline,
        priority: priority,
        isActive: isActive,
      );
      await loadNewsTickerItems();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Newsticker-Eintrag aktualisiert',
      );
    } catch (e, stackTrace) {
      _logger.e('Error updating news ticker item', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> moveNewsTickerItem({
    required String newsTickerItemId,
    required bool moveUp,
  }) async {
    final current = [...state.newsTickerItems]
      ..sort((a, b) {
        final ap = int.tryParse(a['priority']?.toString() ?? '0') ?? 0;
        final bp = int.tryParse(b['priority']?.toString() ?? '0') ?? 0;
        return ap.compareTo(bp);
      });

    final idx = current.indexWhere((e) => e['id'] == newsTickerItemId);
    if (idx < 0) return;
    final targetIdx = moveUp ? idx - 1 : idx + 1;
    if (targetIdx < 0 || targetIdx >= current.length) return;

    final currentItem = current[idx];
    final targetItem = current[targetIdx];
    final currentPriority =
        int.tryParse(currentItem['priority']?.toString() ?? '0') ?? 0;
    final targetPriority =
        int.tryParse(targetItem['priority']?.toString() ?? '0') ?? 0;

    state =
        state.copyWith(isLoading: true, errorMessage: '', successMessage: '');
    try {
      await repository.updateNewsTickerItemPriority(
        newsTickerItemId: currentItem['id'] as String,
        priority: targetPriority,
      );
      await repository.updateNewsTickerItemPriority(
        newsTickerItemId: targetItem['id'] as String,
        priority: currentPriority,
      );
      await loadNewsTickerItems();
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Newsticker-Reihenfolge aktualisiert',
      );
    } catch (e, stackTrace) {
      _logger.e('Error moving news ticker item', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> deleteCmsRow({
    required String table,
    required String id,
  }) async {
    state =
        state.copyWith(isLoading: true, errorMessage: '', successMessage: '');
    try {
      await repository.deleteCmsRow(table: table, id: id);
      state = state.copyWith(
          isLoading: false, successMessage: 'Zeile aus $table gelöscht');
    } catch (e, stackTrace) {
      _logger.e('Error deleting row from $table', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> generateCalendarEvents(Season season) async {
    _logger.i('Generating calendar events for season: $season');
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      await generateCalendarEventsUseCase.call(season);
      _logger.i('Calendar events generated successfully');
      state = state.copyWith(isLoading: false);
    } catch (e, stackTrace) {
      _logger.e('Error generating calendar events', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final contentRepositoryProvider = Provider<ContentRepositoryImpl>((ref) {
  final supabaseClient = ref.read(supabaseClientProvider);
  final dataSource = ContentDataSource(supabaseClient);
  return ContentRepositoryImpl(dataSource);
});

final addShowProvider = Provider<AddShow>((ref) {
  final repository = ref.read(contentRepositoryProvider);
  return AddShow(repository);
});

final addSeasonProvider = Provider<AddSeason>((ref) {
  final repository = ref.read(contentRepositoryProvider);
  return AddSeason(repository);
});

final addAttendeeProvider = Provider<AddAttendee>((ref) {
  final repository = ref.read(contentRepositoryProvider);
  return AddAttendee(repository);
});

final generateCalendarEventsProvider = Provider<GenerateCalendarEvents>((ref) {
  final repository = ref.read(contentRepositoryProvider);
  return GenerateCalendarEvents(repository);
});

final contentNotifierProvider =
    StateNotifierProvider<ContentNotifier, ContentState>((ref) {
  final repository = ref.read(contentRepositoryProvider);
  final addShow = ref.read(addShowProvider);
  final addSeason = ref.read(addSeasonProvider);
  final addAttendee = ref.read(addAttendeeProvider);
  final generateCalendarEvents = ref.read(generateCalendarEventsProvider);
  return ContentNotifier(
      repository, addShow, addSeason, addAttendee, generateCalendarEvents);
});
