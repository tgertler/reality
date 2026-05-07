import '../../domain/entities/resolved_calendar_event.dart';

int compareCalendarShowEvents(
  ResolvedCalendarEvent a,
  ResolvedCalendarEvent b,
  Set<String> favoriteShowIds,
) {
  final priorityCompare = _eventPriority(a, favoriteShowIds)
      .compareTo(_eventPriority(b, favoriteShowIds));
  if (priorityCompare != 0) {
    return priorityCompare;
  }

  final subtypeCompare = _specialSubtypePriority(a.showEventSubtype)
      .compareTo(_specialSubtypePriority(b.showEventSubtype));
  if (subtypeCompare != 0) {
    return subtypeCompare;
  }

  final timeCompare = a.startDatetime.compareTo(b.startDatetime);
  if (timeCompare != 0) {
    return timeCompare;
  }

  final titleA =
      (a.showEventShowTitle ?? a.showEventShowShortTitle ?? '').toLowerCase();
  final titleB =
      (b.showEventShowTitle ?? b.showEventShowShortTitle ?? '').toLowerCase();
  if (titleA != titleB) {
    return titleA.compareTo(titleB);
  }

  return a.calendarEventId.compareTo(b.calendarEventId);
}

int _eventPriority(
  ResolvedCalendarEvent event,
  Set<String> favoriteShowIds,
) {
  final showId = event.showEventShowId;
  if (showId != null && favoriteShowIds.contains(showId)) {
    return 0;
  }

  if (_isSpecialSubtype(event.showEventSubtype)) {
    return 1;
  }

  return 2;
}

int _specialSubtypePriority(String? subtype) {
  switch ((subtype ?? '').trim().toLowerCase()) {
    case 'premiere':
      return 0;
    case 'finale':
      return 1;
    case 'reunion':
      return 2;
    default:
      return 3;
  }
}

bool _isSpecialSubtype(String? subtype) {
  final normalized = (subtype ?? '').trim().toLowerCase();
  return normalized == 'premiere' ||
      normalized == 'finale' ||
      normalized == 'reunion';
}
