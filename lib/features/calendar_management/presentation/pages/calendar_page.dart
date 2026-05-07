import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/widgets/top_bar_widget.dart';
import 'package:frontend/features/calendar_management/presentation/providers/filter_overlay_provider.dart';
import 'package:frontend/features/calendar_management/presentation/providers/filter_overlay_search_provider.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/calendar_body_widget.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/calendar_next_three_days_view_widget.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/calendar_month_view_widget.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/custom_weekly_date_picker_widget.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/datepicker_topbar_widget.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/filter_overlay_search_widget.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/filter_overlay_widget.dart';
import 'package:frontend/features/calendar_management/presentation/providers/calendar_view_mode_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(calendarViewModeProvider);
    final isFilterOverlayVisible = ref.watch(filterOverlayProvider);
    final isFilterOverlaySearchVisible = ref.watch(filterOverlaySearchProvider);
    const overlayTopInset = 123.0;

    return Scaffold(
      appBar: TopBarWidget(),
      body: Stack(
        children: [
          Container(
        child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
              height: 72,
              width: double.infinity,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    child: Transform.rotate(
                      angle: -0.015,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            color: AppColors.pop,
                            child: Text(
                              'TRASH CALENDAR',
                              style: GoogleFonts.montserrat(
                                color: const Color(0xFF1E1E1E),
                                fontSize: 28,
                                height: 1.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(0, 2, 0, 6),
              child: DatepickerTopbarWidget()),
          if (viewMode == CalendarViewMode.week)
            Container(
              width: double.infinity,
              color: const Color.fromARGB(255, 32, 32, 32),
              child: const Padding(
                padding: EdgeInsets.only(top: 2.0, bottom: 2.0),
                child: CustomWeeklyDatePickerWidget(),
              ),
            )
          else
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color.fromARGB(255, 32, 32, 32),
                child: switch (viewMode) {
                  CalendarViewMode.week => const SizedBox.shrink(),
                  CalendarViewMode.month => const CalendarMonthViewWidget(),
                  CalendarViewMode.nextThreeDays =>
                    const CalendarNextThreeDaysViewWidget(),
                },
              ),
            ),
          if (viewMode == CalendarViewMode.week) CalendarBodyWidget(),
        ],
        ),
      ),
          TapRegion(
            onTapOutside: (_) {
              ref.read(filterOverlayProvider.notifier).state = false;
              ref.read(filterOverlaySearchProvider.notifier).state = false;
            },
            child: Stack(
              children: [
                if (isFilterOverlayVisible)
                  Positioned(
                    top: overlayTopInset,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: FilterOverlayWidget(
                      onClose: () {
                        ref.read(filterOverlayProvider.notifier).state = false;
                      },
                    ),
                  ),
                if (isFilterOverlaySearchVisible)
                  Positioned(
                    top: overlayTopInset,
                    left: 0,
                    right: 0,
                    bottom: 0,
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
        ],
      ),
    );
  }
}
