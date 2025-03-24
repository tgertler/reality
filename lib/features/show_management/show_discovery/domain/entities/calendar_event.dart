class CalendarEvent {
  final String id;
  final String showId;
  final String title;
  final DateTime start;
  final DateTime? end;
  final String? location;
  final String? type;

  const CalendarEvent({
    required this.id,
    required this.showId,
    required this.title,
    required this.start,
    this.end,
    this.location,
    this.type,
  });
}
