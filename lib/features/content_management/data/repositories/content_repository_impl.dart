import 'package:logger/logger.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/show.dart';
import '../../domain/entities/season.dart';
import '../../domain/entities/attendee.dart';
import '../../domain/repositories/content_repository.dart';
import '../sources/content_data_source.dart';

class ContentRepositoryImpl implements ContentRepository {
  final ContentDataSource dataSource;
  final Logger _logger = getLogger('ContentRepositoryImpl');

  ContentRepositoryImpl(this.dataSource);

  @override
  Future<void> addShow(Show show) async {
    _logger.i('Adding show: $show');
    try {
      await dataSource.addShow(show);
      _logger.i('Show added successfully');
    } catch (e, stackTrace) {
      _logger.e('Error adding show', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> addSeason(Season season) async {
    _logger.i('Adding season: $season');
    try {
      await dataSource.addSeason(season);
      _logger.i('Season added successfully');

      // try {
      //   await generateCalendarEvents(season);
      // } catch (e, stackTrace) {
      //   if (_isIgnorableBingoGenerationError(e)) {
      //     _logger.w(
      //       'Season created, but bingo auto-generation was skipped during CMS creation: $e',
      //     );
      //     return;
      //   }
      //   _logger.e('Error generating calendar events after season creation', e,
      //       stackTrace);
      //   rethrow;
      // }
    } catch (e, stackTrace) {
      _logger.e('Error adding season', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> addAttendee(Attendee attendee) async {
    _logger.i('Adding attendee: $attendee');
    try {
      await dataSource.addAttendee(attendee);
      _logger.i('Attendee added successfully');
    } catch (e, stackTrace) {
      _logger.e('Error adding attendee', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> generateCalendarEvents(Season season) async {
    _logger.i('Generating calendar events for season: $season');
    try {
      await dataSource.generateCalendarEvents(season);
      _logger.i('Calendar events generated successfully');
    } catch (e, stackTrace) {
      _logger.e('Error generating calendar events', e, stackTrace);
      rethrow;
    }
  }

  @override
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
    try {
      await dataSource.updateShow(
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
    } catch (e, stackTrace) {
      _logger.e('Error updating show', e, stackTrace);
      rethrow;
    }
  }

  @override
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
    try {
      await dataSource.updateSeason(
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
    } catch (e, stackTrace) {
      _logger.e('Error updating season', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Show>> getShows() async {
    try {
      return await dataSource.getShows();
    } catch (e, stackTrace) {
      _logger.e('Error loading shows', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Season>> getSeasonsByShowId(String showId) async {
    try {
      return await dataSource.getSeasonsByShowId(showId);
    } catch (e, stackTrace) {
      _logger.e('Error loading seasons for show $showId', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Season>> getAllSeasons() async {
    try {
      return await dataSource.getAllSeasons();
    } catch (e, stackTrace) {
      _logger.e('Error loading all seasons', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCreators() async {
    try {
      return await dataSource.getCreators();
    } catch (e, stackTrace) {
      _logger.e('Error loading creators', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCreatorEvents() async {
    try {
      return await dataSource.getCreatorEvents();
    } catch (e, stackTrace) {
      _logger.e('Error loading creator events', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTrashEvents() async {
    try {
      return await dataSource.getTrashEvents();
    } catch (e, stackTrace) {
      _logger.e('Error loading trash events', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getShowsTableRows() async {
    try {
      return await dataSource.getShowsTableRows();
    } catch (e, stackTrace) {
      _logger.e('Error loading show table rows', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSeasonsTableRowsByShowId(
      String showId) async {
    try {
      return await dataSource.getSeasonsTableRowsByShowId(showId);
    } catch (e, stackTrace) {
      _logger.e('Error loading season table rows', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getShowEventsBySeasonId(
      String seasonId) async {
    try {
      return await dataSource.getShowEventsBySeasonId(seasonId);
    } catch (e, stackTrace) {
      _logger.e('Error loading show events', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCalendarEventsByShowEventId(
      String showEventId) async {
    try {
      return await dataSource.getCalendarEventsByShowEventId(showEventId);
    } catch (e, stackTrace) {
      _logger.e('Error loading calendar events', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String> addCreator({
    required String name,
    String? description,
    String? avatarUrl,
    String? youtubeChannelUrl,
    String? instagramUrl,
    String? tiktokUrl,
  }) async {
    try {
      return await dataSource.addCreator(
        name: name,
        description: description,
        avatarUrl: avatarUrl,
        youtubeChannelUrl: youtubeChannelUrl,
        instagramUrl: instagramUrl,
        tiktokUrl: tiktokUrl,
      );
    } catch (e, stackTrace) {
      _logger.e('Error creating creator', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateCreator({
    required String creatorId,
    String? name,
    String? description,
    String? avatarUrl,
    String? youtubeChannelUrl,
    String? instagramUrl,
    String? tiktokUrl,
  }) async {
    try {
      await dataSource.updateCreator(
        creatorId: creatorId,
        name: name,
        description: description,
        avatarUrl: avatarUrl,
        youtubeChannelUrl: youtubeChannelUrl,
        instagramUrl: instagramUrl,
        tiktokUrl: tiktokUrl,
      );
    } catch (e, stackTrace) {
      _logger.e('Error updating creator', e, stackTrace);
      rethrow;
    }
  }

  @override
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
    try {
      await dataSource.addCreatorEvent(
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
    } catch (e, stackTrace) {
      _logger.e('Error creating creator event', e, stackTrace);
      rethrow;
    }
  }

  @override
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
    try {
      await dataSource.updateCreatorEvent(
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
    } catch (e, stackTrace) {
      _logger.e('Error updating creator event', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateShowEvent({
    required String showEventId,
    String? showId,
    String? seasonId,
    String? eventSubtype,
    int? episodeNumber,
    String? description,
  }) async {
    try {
      await dataSource.updateShowEvent(
        showEventId: showEventId,
        showId: showId,
        seasonId: seasonId,
        eventSubtype: eventSubtype,
        episodeNumber: episodeNumber,
        description: description,
      );
    } catch (e, stackTrace) {
      _logger.e('Error updating show event', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> addShowEventWithCalendarEvent({
    required String showId,
    required String seasonId,
    required String eventSubtype,
    required int episodeNumber,
    String? description,
    required DateTime startDatetime,
    Duration? duration,
  }) async {
    try {
      await dataSource.addShowEventWithCalendarEvent(
        showId: showId,
        seasonId: seasonId,
        eventSubtype: eventSubtype,
        episodeNumber: episodeNumber,
        description: description,
        startDatetime: startDatetime,
        duration: duration,
      );
    } catch (e, stackTrace) {
      _logger.e('Error creating show event with calendar event', e, stackTrace);
      rethrow;
    }
  }

  @override
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
    try {
      await dataSource.updateCalendarEvent(
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
    } catch (e, stackTrace) {
      _logger.e('Error updating calendar event', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> createCreatorEventBlockForSeason({
    required String creatorId,
    required String showId,
    required String seasonId,
    required String eventKind,
    String? titlePrefix,
    String? descriptionTemplate,
    Duration? duration,
  }) async {
    try {
      return await dataSource.createCreatorEventBlockForSeason(
        creatorId: creatorId,
        showId: showId,
        seasonId: seasonId,
        eventKind: eventKind,
        titlePrefix: titlePrefix,
        descriptionTemplate: descriptionTemplate,
        duration: duration,
      );
    } catch (e, stackTrace) {
      _logger.e('Error creating creator event block', e, stackTrace);
      rethrow;
    }
  }

  @override
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
    try {
      await dataSource.addTrashEvent(
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
        duration: duration,
      );
    } catch (e, stackTrace) {
      _logger.e('Error creating trash event', e, stackTrace);
      rethrow;
    }
  }

  @override
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
    try {
      return await dataSource.addTrashEventSeries(
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
    } catch (e, stackTrace) {
      _logger.e('Error creating trash event series', e, stackTrace);
      rethrow;
    }
  }

  @override
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
    try {
      await dataSource.updateTrashEvent(
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
    } catch (e, stackTrace) {
      _logger.e('Error updating trash event', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getFeedItems() async {
    try {
      return await dataSource.getFeedItems();
    } catch (e, stackTrace) {
      _logger.e('Error loading feed items', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> addQuoteOfWeekFeedItem({
    required String quote,
    required String speakerName,
    required String showId,
    required String showTitle,
    int? seasonNumber,
    int? episodeNumber,
    String? ctaLabel,
  }) async {
    try {
      await dataSource.addQuoteOfWeekFeedItem(
        quote: quote,
        speakerName: speakerName,
        showId: showId,
        showTitle: showTitle,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
        ctaLabel: ctaLabel,
      );
    } catch (e, stackTrace) {
      _logger.e('Error adding quote of week feed item', e, stackTrace);
      rethrow;
    }
  }

  @override
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
    try {
      await dataSource.addThrowbackFeedItem(
        label: label,
        momentText: momentText,
        showId: showId,
        showTitle: showTitle,
        seasonNumber: seasonNumber,
        episodeNumber: episodeNumber,
        ctaLabel: ctaLabel,
        stickerLabel: stickerLabel,
      );
    } catch (e, stackTrace) {
      _logger.e('Error adding throwback feed item', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateFeedItem({
    required String feedItemId,
    String? itemType,
    Map<String, dynamic>? data,
    DateTime? feedTimestamp,
    int? priority,
  }) async {
    try {
      await dataSource.updateFeedItem(
        feedItemId: feedItemId,
        itemType: itemType,
        data: data,
        feedTimestamp: feedTimestamp,
        priority: priority,
      );
    } catch (e, stackTrace) {
      _logger.e('Error updating feed item', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateFeedItemPriority({
    required String feedItemId,
    required int priority,
  }) async {
    try {
      await dataSource.updateFeedItemPriority(
        feedItemId: feedItemId,
        priority: priority,
      );
    } catch (e, stackTrace) {
      _logger.e('Error updating feed item priority', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getNewsTickerItems() async {
    try {
      return await dataSource.getNewsTickerItems();
    } catch (e, stackTrace) {
      _logger.e('Error loading news ticker items', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> addNewsTickerItem({
    required String headline,
    int? priority,
    bool isActive = true,
  }) async {
    try {
      await dataSource.addNewsTickerItem(
        headline: headline,
        priority: priority,
        isActive: isActive,
      );
    } catch (e, stackTrace) {
      _logger.e('Error adding news ticker item', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateNewsTickerItem({
    required String newsTickerItemId,
    String? headline,
    int? priority,
    bool? isActive,
  }) async {
    try {
      await dataSource.updateNewsTickerItem(
        newsTickerItemId: newsTickerItemId,
        headline: headline,
        priority: priority,
        isActive: isActive,
      );
    } catch (e, stackTrace) {
      _logger.e('Error updating news ticker item', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateNewsTickerItemPriority({
    required String newsTickerItemId,
    required int priority,
  }) async {
    try {
      await dataSource.updateNewsTickerItemPriority(
        newsTickerItemId: newsTickerItemId,
        priority: priority,
      );
    } catch (e, stackTrace) {
      _logger.e('Error updating news ticker item priority', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteCmsRow({
    required String table,
    required String id,
  }) async {
    try {
      await dataSource.deleteCmsRow(table: table, id: id);
    } catch (e, stackTrace) {
      _logger.e('Error deleting row from $table', e, stackTrace);
      rethrow;
    }
  }
}
