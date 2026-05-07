class CalendarEvent {
  final String calendarEventId;
  final DateTime startDatetime;
  final DateTime endDatetime;
  final String eventType; // premiere, regular, finale
  final String? showEventId; // FK to show_events

  CalendarEvent({
    required this.calendarEventId,
    required this.startDatetime,
    required this.endDatetime,
    required this.eventType,
    this.showEventId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': calendarEventId,
      'start_datetime': startDatetime.toUtc().toIso8601String(),
      'end_datetime': endDatetime.toUtc().toIso8601String(),
      'event_type': eventType,
      'event_entity_type': 'show_event',
      if (showEventId != null) 'show_event_id': showEventId,
    };
  }
}
