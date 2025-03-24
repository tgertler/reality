class CalendarEvent {
  final String calendarEventId;
  final String showId;
  final String? seasonId;
  final DateTime startDatetime;
  final DateTime endDatetime;

  CalendarEvent({
    required this.calendarEventId,
    required this.showId,
    required this.seasonId,
    required this.startDatetime,
    required this.endDatetime,
  });
}