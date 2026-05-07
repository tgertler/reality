import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CalendarViewMode {
  week,
  month,
  nextThreeDays,
}

final calendarViewModeProvider =
    StateProvider<CalendarViewMode>((ref) => CalendarViewMode.week);
