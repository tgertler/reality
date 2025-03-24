import 'package:frontend/features/calendar_management/domain/entities/season.dart';

import 'calendar_event.dart';
import 'show.dart';

class CalendarEventWithShow {
  final CalendarEvent calendarEvent;
  final Show show;
  final Season season;

  CalendarEventWithShow({
    required this.calendarEvent,
    required this.show,
    required this.season,
  });
}
