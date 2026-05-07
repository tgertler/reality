import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/providers/streaming_filter_provider.dart';
import 'package:frontend/core/providers/trash_event_city_filter_provider.dart';
import 'package:frontend/features/calendar_management/domain/entities/resolved_calendar_event.dart';
import 'package:frontend/features/calendar_management/presentation/providers/calendar_events_provider.dart';
import 'package:frontend/features/calendar_management/presentation/providers/category_filter_provider.dart';
import 'package:frontend/features/calendar_management/presentation/providers/datepicker_provider.dart';
import 'package:frontend/features/calendar_management/presentation/providers/favorites_only_filter_provider.dart';
import 'package:frontend/features/calendar_management/presentation/providers/page_controller.dart';
import 'package:frontend/features/calendar_management/presentation/utils/calendar_event_grouping.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/calendar_creator_event_card_widget.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/calendar_resolved_show_event_card_widget.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/calendar_trash_event_card_widget.dart';
import 'package:frontend/features/favorites_management/presentation/providers/favorites_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarMonthViewWidget extends ConsumerStatefulWidget {
  const CalendarMonthViewWidget({super.key});

  @override
  ConsumerState<CalendarMonthViewWidget> createState() =>
      _CalendarMonthViewWidgetState();
}

class _CalendarMonthViewWidgetState
    extends ConsumerState<CalendarMonthViewWidget> {
  static const int _pageOffset = 500;
  static const _weekdayLabels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = ref.read(calendarMonthPageControllerProvider).controller;
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(datepickerNotifierProvider).selectedDate;
    final today = DateTime.now();
    final desiredPage = _pageOffset +
        ((selectedDate.year - today.year) * 12) +
        (selectedDate.month - today.month);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      final currentPage = _pageController.page?.round();
      if (currentPage != desiredPage) {
        _pageController.jumpToPage(desiredPage);
      }
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          child: Row(
            children: _weekdayLabels
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (pageIndex) {
              final monthIndex = pageIndex - _pageOffset;
              final displayedMonth =
                  DateTime(today.year, today.month + monthIndex, 1);
              final currentSelected =
                  ref.read(datepickerNotifierProvider).selectedDate;
              final lastDayInMonth =
                  DateTime(displayedMonth.year, displayedMonth.month + 1, 0)
                      .day;
              final nextDay = currentSelected.day > lastDayInMonth
                  ? lastDayInMonth
                  : currentSelected.day;
              ref.read(datepickerNotifierProvider.notifier).changeDate(
                    DateTime(
                      displayedMonth.year,
                      displayedMonth.month,
                      nextDay,
                    ),
                  );
            },
            itemBuilder: (context, pageIndex) {
              final monthIndex = pageIndex - _pageOffset;
              final displayedMonth =
                  DateTime(today.year, today.month + monthIndex, 1);

              return _MonthPage(
                displayedMonth: displayedMonth,
                selectedDate: selectedDate,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MonthPage extends ConsumerWidget {
  final DateTime displayedMonth;
  final DateTime selectedDate;

  const _MonthPage({
    required this.displayedMonth,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthEventsAsync =
        ref.watch(calendarResolvedEventsForMonthProvider(displayedMonth));

    return monthEventsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => Center(
        child: Text(
          'Monatsansicht konnte nicht geladen werden.',
          style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 13),
        ),
      ),
      data: (eventsByDate) {
        final helper = const _MonthViewHelper();
        final gridDays = helper.monthGridDays(displayedMonth);
        final visibleEventsByDate = helper.applyFilters(ref, eventsByDate);

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
          itemCount: gridDays.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.52,
            mainAxisSpacing: 0,
            crossAxisSpacing: 0,
          ),
          itemBuilder: (context, index) {
            final day = gridDays[index];
            final dayEvents =
                visibleEventsByDate[helper.dayKey(day)] ?? const [];
            final isSelected = helper.isSameDay(day, selectedDate);
            final isToday = helper.isSameDay(day, DateTime.now());
            final inCurrentMonth = day.month == displayedMonth.month;

            return _MonthDayCell(
              day: day,
              events: dayEvents,
              inCurrentMonth: inCurrentMonth,
              isSelected: isSelected,
              isToday: isToday,
              onTap: () {
                if (isSelected) {
                  _showDayEventsSheet(context, day, dayEvents);
                  return;
                }

                ref.read(datepickerNotifierProvider.notifier).changeDate(day);
                ref
                    .read(calendarEventsNotifierProvider.notifier)
                    .fetchResolvedEventsForDate(day);
              },
            );
          },
        );
      },
    );
  }

  void _showDayEventsSheet(
    BuildContext context,
    DateTime day,
    List<ResolvedCalendarEvent> events,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${day.day}.${day.month}.${day.year}',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (events.isEmpty)
                    Text(
                      'Keine Events an diesem Tag.',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: Colors.white54,
                      ),
                    )
                  else
                    ...groupConsecutiveByKey<ResolvedCalendarEvent>(
                      events,
                      (event) => event.relatedShowId,
                    ).map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(
                          left: entry.isContinuation ? 16 : 0,
                          bottom: 8,
                        ),
                        child: Transform.scale(
                          scale: entry.isContinuation ? 0.97 : 1,
                          alignment: Alignment.topLeft,
                          child: _buildDetailCard(entry.item),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailCard(ResolvedCalendarEvent event) {
    if (event.isShowEvent) {
      return CalendarResolvedShowEventCard(event: event);
    }
    if (event.isCreatorEvent) {
      return CalendarCreatorEventCard(event: event);
    }
    return CalendarTrashEventCard(event: event);
  }
}

class _MonthViewHelper {
  const _MonthViewHelper();

  Map<String, List<ResolvedCalendarEvent>> applyFilters(
    WidgetRef ref,
    Map<String, List<ResolvedCalendarEvent>> eventsByDate,
  ) {
    final favoritesOnly = ref.watch(favoritesOnlyFilterProvider);
    final selectedGenres = ref.watch(selectedGenreFiltersProvider);
    final streamingFilter = ref.watch(streamingServiceFilterProvider);
    final selectedTrashCity = ref.watch(trashEventCityFilterProvider);
    final favState = ref.watch(favoritesNotifierProvider);

    final favoriteShowIds = favState.favoriteShows.map((s) => s.showId).toSet();
    final filtered = <String, List<ResolvedCalendarEvent>>{};

    eventsByDate.forEach((key, value) {
      filtered[key] = value.where((e) {
        if (favoritesOnly && !favoriteShowIds.contains(e.relatedShowId)) {
          return false;
        }

        if (e.isShowEvent &&
            !passesStreamingFilter(
                e.showEventStreamingOption, streamingFilter)) {
          return false;
        }

        if (e.isShowEvent && selectedGenres.isNotEmpty) {
          final rawCategory = (e.showEventGenre ?? '').trim().toLowerCase();
          if (rawCategory.isEmpty) {
            return false;
          }

          final categoryTokens = rawCategory
              .split(RegExp(r'[,/|]'))
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toSet();

          if (!selectedGenres.any(
            (genre) => categoryTokens.contains(genre.trim().toLowerCase()),
          )) {
            return false;
          }
        }

        if (e.isTrashEvent &&
            !passesTrashCityFilter(e.trashEventLocation, selectedTrashCity)) {
          return false;
        }

        return true;
      }).toList()
        ..sort((a, b) => a.startDatetime.compareTo(b.startDatetime));
    });

    return filtered;
  }

  List<DateTime> monthGridDays(DateTime selectedDate) {
    final firstOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastOfMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    final gridStart =
        firstOfMonth.subtract(Duration(days: firstOfMonth.weekday - 1));
    final gridEnd = lastOfMonth.add(Duration(days: 7 - lastOfMonth.weekday));

    final days = <DateTime>[];
    var cursor = gridStart;
    while (!cursor.isAfter(gridEnd)) {
      days.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return days;
  }

  String dayKey(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.toIso8601String();
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _MonthDayCell extends StatelessWidget {
  final DateTime day;
  final List<ResolvedCalendarEvent> events;
  final bool inCurrentMonth;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _MonthDayCell({
    required this.day,
    required this.events,
    required this.inCurrentMonth,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? const Color(0xFFF890FF)
        : isToday
            ? Colors.white54
            : Colors.white12;

    final bgColor =
        isSelected ? const Color(0xFF2A1B2A) : const Color(0xFF151515);

    final dayColor = !inCurrentMonth
        ? Colors.white24
        : isSelected
            ? const Color(0xFFF890FF)
            : Colors.white70;

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1.0),
        ),
        padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${day.day}',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: dayColor,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (events.isEmpty || constraints.maxHeight <= 0) {
                    return const SizedBox.shrink();
                  }

                  const chipHeight = 20.0;
                  const moreHeight = 12.0;
                  final groupedEvents =
                      groupConsecutiveByKey<ResolvedCalendarEvent>(
                    events,
                    (event) => event.relatedShowId,
                  );
                  final maxVisible =
                      (constraints.maxHeight / chipHeight).floor().clamp(1, 3);
                  final visibleCount = groupedEvents.length > maxVisible
                      ? maxVisible - 1
                      : maxVisible;
                  final safeVisibleCount =
                      visibleCount.clamp(1, groupedEvents.length);
                  final hiddenCount = groupedEvents.length - safeVisibleCount;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...groupedEvents.take(safeVisibleCount).map(
                            (entry) => _CompactEventChip(
                              entry.item,
                              isContinuation: entry.isContinuation,
                            ),
                          ),
                      if (hiddenCount > 0 &&
                          constraints.maxHeight >= (chipHeight + moreHeight))
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            '+$hiddenCount',
                            style: GoogleFonts.dmSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactEventChip extends StatelessWidget {
  final ResolvedCalendarEvent event;
  final bool isContinuation;

  const _CompactEventChip(
    this.event, {
    this.isContinuation = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = _label(event);
    final color = _accentColor(event);

    return Container(
      height: isContinuation ? 16 : 18,
      margin: EdgeInsets.only(
        left: isContinuation ? 8 : 0,
        bottom: 2,
      ),
      padding: EdgeInsets.fromLTRB(
        isContinuation ? 5 : 3,
        2,
        3,
        2,
      ),
      decoration: BoxDecoration(
        color:
            isContinuation ? const Color(0xFF181818) : const Color(0xFF1E1E1E),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.dmSans(
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
            height: 1.0,
          ),
        ),
      ),
    );
  }

  String _label(ResolvedCalendarEvent event) {
    if (event.isShowEvent) {
      final title =
          event.showEventShowShortTitle ?? event.showEventShowTitle ?? 'Show';
      final episode = event.showEventEpisodeNumber;
      if (episode != null) {
        return '$title E$episode';
      }
      return title;
    }

    if (event.isCreatorEvent) {
      return event.creatorName ?? event.creatorEventTitle ?? 'Creator';
    }

    return event.trashEventTitle ?? 'Community';
  }

  Color _accentColor(ResolvedCalendarEvent event) {
    if (event.isShowEvent) return const Color(0xFFF890FF);
    if (event.isCreatorEvent) return const Color(0xFF4DB6FF);
    return const Color(0xFFFFD700);
  }
}
