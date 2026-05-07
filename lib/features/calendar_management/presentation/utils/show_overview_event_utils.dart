import 'package:frontend/features/calendar_management/domain/entities/calendar_event_with_show.dart';

List<CalendarEventWithShow> buildShowOverviewEventList({
  required List<CalendarEventWithShow> allEvents,
  CalendarEventWithShow? nextEvent,
}) {
  if (allEvents.isEmpty) {
    return const [];
  }

  final targetSeasonId = _resolveTargetSeasonId(allEvents, nextEvent);

  final filtered = allEvents.where((event) {
    if (targetSeasonId == null || targetSeasonId.isEmpty) {
      return true;
    }

    final seasonId = event.calendarEvent.seasonId ?? event.season.seasonId;
    return seasonId == targetSeasonId;
  }).toList();

  filtered.sort((a, b) =>
      a.calendarEvent.startDatetime.compareTo(b.calendarEvent.startDatetime));

  return filtered;
}

String? _resolveTargetSeasonId(
  List<CalendarEventWithShow> events,
  CalendarEventWithShow? nextEvent,
) {
  final nextSeasonId =
      nextEvent?.calendarEvent.seasonId ?? nextEvent?.season.seasonId;
  if (nextSeasonId != null && nextSeasonId.isNotEmpty) {
    return nextSeasonId;
  }

  final sorted = [...events]..sort((a, b) {
      final seasonCompare =
          (b.season.seasonNumber ?? -1).compareTo(a.season.seasonNumber ?? -1);
      if (seasonCompare != 0) {
        return seasonCompare;
      }
      return b.calendarEvent.startDatetime
          .compareTo(a.calendarEvent.startDatetime);
    });

  if (sorted.isEmpty) {
    return null;
  }

  return sorted.first.calendarEvent.seasonId ?? sorted.first.season.seasonId;
}
