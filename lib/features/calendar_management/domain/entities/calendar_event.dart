class CalendarEvent {
  final String calendarEventId;
  final String showId;
  final String? seasonId;
  final DateTime startDatetime;
  final DateTime endDatetime;
  final int? dramaLevel;

  /// 'show_event' | 'creator_event' | 'trash_event'
  final String? eventEntityType;

  /// FK to show_events (set when eventEntityType == 'show_event')
  final String? showEventId;

  /// FK to creator_events (set when eventEntityType == 'creator_event')
  final String? creatorEventId;

  /// FK to trash_events (set when eventEntityType == 'trash_event')
  final String? trashEventId;

  /// Joined from show_events (episode_number)
  final int? episodeNumber;

  /// Joined from show_events (event_subtype): 'premiere' | 'episode' | 'finale'
  final String? eventSubtype;

  CalendarEvent({
    required this.calendarEventId,
    required this.showId,
    required this.seasonId,
    required this.startDatetime,
    required this.endDatetime,
    required this.dramaLevel,
    this.eventEntityType,
    this.showEventId,
    this.creatorEventId,
    this.trashEventId,
    this.episodeNumber,
    this.eventSubtype,
  });
}
