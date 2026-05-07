import '../entities/show.dart';
import '../entities/season.dart';
import '../entities/attendee.dart';

abstract class ContentRepository {
  Future<void> addShow(Show show);
  Future<void> addSeason(Season season);
  Future<void> addAttendee(Attendee attendee);
  Future<void> generateCalendarEvents(Season season);
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
  });
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
  });
  Future<List<Show>> getShows();
  Future<List<Season>> getSeasonsByShowId(String showId);
  Future<List<Season>> getAllSeasons();
  Future<List<Map<String, dynamic>>> getCreators();
  Future<List<Map<String, dynamic>>> getCreatorEvents();
  Future<List<Map<String, dynamic>>> getTrashEvents();
  Future<List<Map<String, dynamic>>> getShowsTableRows();
  Future<List<Map<String, dynamic>>> getSeasonsTableRowsByShowId(String showId);
  Future<List<Map<String, dynamic>>> getShowEventsBySeasonId(String seasonId);
  Future<List<Map<String, dynamic>>> getCalendarEventsByShowEventId(
      String showEventId);
  Future<String> addCreator({
    required String name,
    String? description,
    String? avatarUrl,
    String? youtubeChannelUrl,
    String? instagramUrl,
    String? tiktokUrl,
  });
  Future<void> updateCreator({
    required String creatorId,
    String? name,
    String? description,
    String? avatarUrl,
    String? youtubeChannelUrl,
    String? instagramUrl,
    String? tiktokUrl,
  });
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
  });
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
  });
  Future<void> updateShowEvent({
    required String showEventId,
    String? showId,
    String? seasonId,
    String? eventSubtype,
    int? episodeNumber,
    String? description,
  });
  Future<void> addShowEventWithCalendarEvent({
    required String showId,
    required String seasonId,
    required String eventSubtype,
    required int episodeNumber,
    String? description,
    required DateTime startDatetime,
    Duration? duration,
  });
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
  });
  Future<int> createCreatorEventBlockForSeason({
    required String creatorId,
    required String showId,
    required String seasonId,
    required String eventKind,
    String? titlePrefix,
    String? descriptionTemplate,
    Duration? duration,
  });
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
  });
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
  });
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
  });
  Future<List<Map<String, dynamic>>> getFeedItems();
  Future<void> addQuoteOfWeekFeedItem({
    required String quote,
    required String speakerName,
    required String showId,
    required String showTitle,
    int? seasonNumber,
    int? episodeNumber,
    String? ctaLabel,
  });
  Future<void> addThrowbackFeedItem({
    required String label,
    required String momentText,
    required String showId,
    required String showTitle,
    int? seasonNumber,
    int? episodeNumber,
    String? ctaLabel,
    String? stickerLabel,
  });
  Future<void> updateFeedItem({
    required String feedItemId,
    String? itemType,
    Map<String, dynamic>? data,
    DateTime? feedTimestamp,
    int? priority,
  });
  Future<void> updateFeedItemPriority({
    required String feedItemId,
    required int priority,
  });
  Future<List<Map<String, dynamic>>> getNewsTickerItems();
  Future<void> addNewsTickerItem({
    required String headline,
    int? priority,
    bool isActive,
  });
  Future<void> updateNewsTickerItem({
    required String newsTickerItemId,
    String? headline,
    int? priority,
    bool? isActive,
  });
  Future<void> updateNewsTickerItemPriority({
    required String newsTickerItemId,
    required int priority,
  });
  Future<void> deleteCmsRow({
    required String table,
    required String id,
  });
}
