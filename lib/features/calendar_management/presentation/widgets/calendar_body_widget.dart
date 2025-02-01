import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/calendar_management/presentation/providers/filter_overlay_search_provider.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/filter_overlay_search_widget.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/filter_overlay_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import '../providers/calendar_events_provider.dart';
import '../providers/datepicker_provider.dart';
import '../providers/filter_overlay_provider.dart';
import 'calendar_event_card_widget.dart';

class CalendarBodyWidget extends ConsumerStatefulWidget {
  const CalendarBodyWidget({Key? key}) : super(key: key);

  @override
  _CalendarBodyWidgetState createState() => _CalendarBodyWidgetState();
}

class _CalendarBodyWidgetState extends ConsumerState<CalendarBodyWidget> {
  @override
  void initState() {
    super.initState();
    final datepickerState = ref.read(datepickerNotifierProvider);
    final notifier = ref.read(calendarEventsNotifierProvider.notifier);
    notifier.fetchEventsForDate(datepickerState.selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting('de_DE', null);
    final datepickerState = ref.watch(datepickerNotifierProvider);
    final state = ref.watch(calendarEventsNotifierProvider);
    final notifier = ref.read(calendarEventsNotifierProvider.notifier);
    final isFilterOverlayVisible = ref.watch(filterOverlayProvider);
    final isFilterOverlaySearchVisible = ref.watch(filterOverlaySearchProvider);

    ref.listen<DatepickerState>(datepickerNotifierProvider, (previous, next) {
      if (previous?.selectedDate != next.selectedDate) {
        notifier.fetchEventsForDate(next.selectedDate);
      }
    });

    return Expanded(
      child: Stack(children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    '${DateFormat('EEEE', 'de_DE').format(datepickerState.selectedDate)}, ${DateFormat('dd', 'de_DE').format(datepickerState.selectedDate)}.',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    itemCount: state.events.length,
                    itemBuilder: (context, index) {
                      final event = state.events[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: CalendarEventCardWidget(
                          calendarEventId:
                              event.calendarEvent.calendarEventId ?? '',
                          startDatetime: event.calendarEvent.startDatetime,
                          endDatetime: event.calendarEvent.endDatetime,
                          showName: event.show.title ?? '',
                          showId: event.calendarEvent.showId ?? '',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        TapRegion(
          onTapOutside: (tap) {
            ref.read(filterOverlayProvider.notifier).state = false;
            ref.read(filterOverlaySearchProvider.notifier).state = false;
          },
          child: Stack(
            children: [
              if (isFilterOverlayVisible)
                Positioned.fill(
                  child: FilterOverlayWidget(
                    onClose: () {
                      ref.read(filterOverlayProvider.notifier).state = false;
                    },
                  ),
                ),
              if (isFilterOverlaySearchVisible)
                Positioned.fill(
                  child: FilterOverlaySearchWidget(
                    onClose: () {
                      ref.read(filterOverlaySearchProvider.notifier).state =
                          false;
                      
                    },
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}
