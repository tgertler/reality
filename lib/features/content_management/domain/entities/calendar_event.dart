class CalendarEvent {
  final String calendarEventId;
  final String showId;
  final String seasonId;
  final DateTime startDatetime;
  final DateTime endDatetime;
  final String eventType; // premiere, regular, finale

  CalendarEvent({
    required this.calendarEventId,
    required this.showId,
    required this.seasonId,
    required this.startDatetime,
    required this.endDatetime,
    required this.eventType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': calendarEventId,
      'show_id': showId,
      'season_id': seasonId,
      'start_datetime': startDatetime.toIso8601String(),
      'end_datetime': endDatetime.toIso8601String(),
      'event_type': eventType,
    };
  }
}