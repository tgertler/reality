import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/calendar_view_mode_provider.dart';
import '../providers/datepicker_provider.dart';
import '../providers/favorites_only_filter_provider.dart';
import '../providers/filter_overlay_provider.dart';
import '../providers/page_controller.dart';

class DatepickerTopbarWidget extends ConsumerWidget {
  const DatepickerTopbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datepickerState = ref.watch(datepickerNotifierProvider);
    final isFilterOverlayVisible = ref.watch(filterOverlayProvider);
    final favoritesOnly = ref.watch(favoritesOnlyFilterProvider);
    final viewMode = ref.watch(calendarViewModeProvider);

    return IgnorePointer(
      ignoring: isFilterOverlayVisible,
      child: SizedBox(
        height: 42,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            ref.read(filterOverlayProvider.notifier).state =
                                !isFilterOverlayVisible;
                          },
                          child: Container(
                            height: 30,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white24),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.filter_list,
                                    size: 15,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Filter',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            ref
                                .read(favoritesOnlyFilterProvider.notifier)
                                .state = !favoritesOnly;
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 30,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              color: favoritesOnly
                                  ? AppColors.pop
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: favoritesOnly
                                  ? null
                                  : Border.all(color: Colors.white24),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    favoritesOnly
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 13,
                                    color: favoritesOnly
                                        ? const Color(0xFF1E1E1E)
                                        : Colors.white54,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Fav',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: favoritesOnly
                                          ? const Color(0xFF1E1E1E)
                                          : Colors.white54,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: Opacity(
                  opacity: isFilterOverlayVisible ? 0.3 : 1.0,
                  child: Center(
                    child: PopupMenuButton<CalendarViewMode>(
                      initialValue: viewMode,
                      color: const Color(0xFF1A1A1A),
                      onSelected: (mode) {
                        ref.read(calendarViewModeProvider.notifier).state =
                            mode;
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: CalendarViewMode.week,
                          child: Text('Tagesansicht'),
                        ),
                        PopupMenuItem(
                          value: CalendarViewMode.month,
                          child: Text('Monatsansicht'),
                        ),
                        PopupMenuItem(
                          value: CalendarViewMode.nextThreeDays,
                          child: Text('3-Tage-Ansicht'),
                        ),
                      ],
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF171717),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                DateFormat('MMMM yyyy', 'de_DE')
                                    .format(datepickerState.selectedDate),
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _viewModeLabel(viewMode),
                              style: GoogleFonts.dmSans(
                                fontSize: 10.5,
                                color: Colors.white54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: Colors.white54,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      ref.read(customPageControllerProvider).jumpToToday();
                      ref
                          .read(calendarMonthPageControllerProvider)
                          .jumpToToday();
                      ref
                          .read(calendarThreeDayPageControllerProvider)
                          .jumpToToday();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ref
                            .read(datepickerNotifierProvider.notifier)
                            .changeDate(DateTime.now());
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.pop,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      height: 30,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'HEUTE',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E1E1E),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _viewModeLabel(CalendarViewMode mode) {
  switch (mode) {
    case CalendarViewMode.week:
      return 'Tag';
    case CalendarViewMode.month:
      return 'Monat';
    case CalendarViewMode.nextThreeDays:
      return '3 Tage';
  }
}
