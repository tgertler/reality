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
import 'package:frontend/features/favorites_management/presentation/providers/favorites_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarNextThreeDaysViewWidget extends ConsumerStatefulWidget {
  const CalendarNextThreeDaysViewWidget({super.key});

  @override
  ConsumerState<CalendarNextThreeDaysViewWidget> createState() =>
      _CalendarNextThreeDaysViewWidgetState();
}

class _CalendarNextThreeDaysViewWidgetState
    extends ConsumerState<CalendarNextThreeDaysViewWidget> {
  static const int _pageOffset = 500;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController =
        ref.read(calendarThreeDayPageControllerProvider).controller;
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(datepickerNotifierProvider).selectedDate;
    final today = DateTime.now();
    final selectedDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final todayDay = DateTime(today.year, today.month, today.day);
    final differenceInDays = selectedDay.difference(todayDay).inDays;
    final desiredPage = _pageOffset + (differenceInDays ~/ 3);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      final currentPage = _pageController.page?.round();
      if (currentPage != desiredPage) {
        _pageController.jumpToPage(desiredPage);
      }
    });

    return PageView.builder(
      controller: _pageController,
      itemBuilder: (context, pageIndex) {
        final windowIndex = pageIndex - _pageOffset;
        final startDate =
            DateTime(today.year, today.month, today.day + (windowIndex * 3));

        return _ThreeDayWindow(
          startDate: startDate,
        );
      },
    );
  }
}

class _ThreeDayWindow extends ConsumerWidget {
  final DateTime startDate;

  const _ThreeDayWindow({required this.startDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync =
        ref.watch(calendarResolvedEventsForThreeDayWindowProvider(startDate));

    return eventsAsync.when(
      loading: () => const SizedBox.expand(
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => SizedBox.expand(
        child: Center(
          child: Text(
            '3-Tage-Ansicht konnte nicht geladen werden.',
            style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 13),
          ),
        ),
      ),
      data: (eventsByDate) {
        final visibleEventsByDate = _applyFilters(ref, eventsByDate);
        final days = List.generate(
          3,
          (index) => DateTime(
            startDate.year,
            startDate.month,
            startDate.day + index,
          ),
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(days.length, (index) {
              final day = days[index];
              return Expanded(
                child: _ThreeDayColumn(
                  day: day,
                  events: visibleEventsByDate[_dayKey(day)] ?? const [],
                  onTapHeader: () {},
                  showLeftBorder: index == 0,
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Map<String, List<ResolvedCalendarEvent>> _applyFilters(
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

  static String _dayKey(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.toIso8601String();
  }
}

class _ThreeDayColumn extends StatelessWidget {
  final DateTime day;
  final List<ResolvedCalendarEvent> events;
  final VoidCallback onTapHeader;
  final bool showLeftBorder;

  const _ThreeDayColumn({
    required this.day,
    required this.events,
    required this.onTapHeader,
    required this.showLeftBorder,
  });

  @override
  Widget build(BuildContext context) {
    final weekday = _weekday(day.weekday);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        border: Border(
          top: const BorderSide(color: Colors.white12),
          bottom: const BorderSide(color: Colors.white12),
          left: showLeftBorder
              ? const BorderSide(color: Colors.white12)
              : BorderSide.none,
          right: const BorderSide(color: Colors.white12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTapHeader,
            child: Row(
              children: [
                Text(
                  '$weekday ${day.day}.${day.month}.',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                // Text(
                //   '${events.length}',
                //   style: GoogleFonts.dmSans(
                //     fontSize: 10,
                //     fontWeight: FontWeight.w700,
                //     color: Colors.white54,
                //   ),
                // ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: events.isEmpty
                ? Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Keine Events',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: Colors.white38,
                      ),
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final groupedEvents =
                          groupConsecutiveByKey<ResolvedCalendarEvent>(
                        events,
                        (event) => event.relatedShowId,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...groupedEvents.take(6).map(
                                (entry) => Padding(
                                  padding: EdgeInsets.only(
                                    left: entry.isContinuation ? 8 : 0,
                                    bottom: 4,
                                  ),
                                  child: _ThreeDayEventTile(
                                    entry.item,
                                    isContinuation: entry.isContinuation,
                                  ),
                                ),
                              ),
                          if (groupedEvents.length > 6)
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Text(
                                '+${groupedEvents.length - 6} weitere',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
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
    );
  }

  String _weekday(int weekday) {
    const labels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return labels[weekday - 1];
  }
}

class _ThreeDayEventTile extends StatelessWidget {
  final ResolvedCalendarEvent event;
  final bool isContinuation;

  const _ThreeDayEventTile(
    this.event, {
    this.isContinuation = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = _label(event);

    return Container(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.fromLTRB(
        isContinuation ? 5 : 6,
        isContinuation ? 4 : 5,
        6,
        isContinuation ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color:
            isContinuation ? const Color(0xFF181818) : const Color(0xFF1E1E1E),
        border: Border.all(color: _accentColor(event).withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: isContinuation ? 10 : 11,
              color: isContinuation ? Colors.white70 : Colors.white,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  String _label(ResolvedCalendarEvent event) {
    if (event.isShowEvent) {
      final title =
          event.showEventShowShortTitle ?? event.showEventShowTitle ?? 'Show';
      final episode = event.showEventEpisodeNumber;
      return episode != null ? '$title · E$episode' : title;
    }

    if (event.isCreatorEvent) {
      return event.creatorEventTitle ?? event.creatorName ?? 'Creator Event';
    }

    return event.trashEventTitle ?? 'Community Event';
  }

  Color _accentColor(ResolvedCalendarEvent event) {
    if (event.isShowEvent) return const Color(0xFFF890FF);
    if (event.isCreatorEvent) return const Color(0xFF4DB6FF);
    return const Color(0xFFFFD700);
  }
}
