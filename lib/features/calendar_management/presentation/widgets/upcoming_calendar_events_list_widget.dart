import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/core/widgets/loading/app_skeleton.dart';
import 'package:frontend/features/calendar_management/domain/entities/calendar_event_with_show.dart';
import 'package:frontend/features/calendar_management/presentation/providers/show_events_provider.dart';
import 'package:frontend/features/calendar_management/presentation/utils/show_overview_event_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class UpcomingCalendarEventsListWidget extends ConsumerStatefulWidget {
  const UpcomingCalendarEventsListWidget({
    super.key,
    required this.showId,
    this.maxItems,
    this.accentColor = AppColors.pop,
  });

  final String showId;
  final int? maxItems;
  final Color accentColor;

  @override
  ConsumerState<UpcomingCalendarEventsListWidget> createState() =>
      _UpcomingCalendarEventsListWidgetState();
}

class _UpcomingCalendarEventsListWidgetState
    extends ConsumerState<UpcomingCalendarEventsListWidget> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(showEventsProvider.notifier).fetchUpcomingEvents(widget.showId);
    });
  }

  @override
  void didUpdateWidget(covariant UpcomingCalendarEventsListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showId != widget.showId) {
      setState(() => _isExpanded = true);
      ref.read(showEventsProvider.notifier).fetchUpcomingEvents(widget.showId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(showEventsProvider);
    final isLoading = state.isLoadingUpcoming && state.upcomingEvents.isEmpty;

    final filteredEvents = buildShowOverviewEventList(
      allEvents: state.upcomingEvents,
      nextEvent: state.nextEvent,
    );

    final events = widget.maxItems == null
        ? filteredEvents
        : filteredEvents.take(widget.maxItems!).toList();

    if (isLoading) {
      return const _UpcomingEventsSkeleton();
    }

    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          //borderRadius: BorderRadius.circular(18),
          border: Border(
            left: BorderSide(
              color: Colors.white.withValues(alpha: 0.4),
              width: 3,
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18.0,
                      vertical: 14.0,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            //borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.event_note_rounded,
                            color: Colors.black,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Events dieser Staffel',
                                style: GoogleFonts.montserrat(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Aktuelle Staffel im Überblick',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${events.length}',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white70,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Container(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Column(
                    children: [
                      if (state.errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.redAccent,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.errorMessage,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: events.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (_, i) => _UpcomingEventTile(
                            event: events[i],
                            accentColor: widget.accentColor,
                            isFirst: i == 0,
                            isLast: i == events.length - 1,
                          ),
                        ),
                    ],
                  ),
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingEventsSkeleton extends StatelessWidget {
  const _UpcomingEventsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          children: [
            const Row(
              children: [
                AppSkeletonBox(
                    width: 30,
                    height: 30,
                    borderRadius: BorderRadius.all(Radius.circular(6))),
                SizedBox(width: 12),
                AppSkeletonBox(width: 120, height: 16),
                SizedBox(width: 8),
                AppSkeletonBox(width: 28, height: 18),
                Spacer(),
                AppSkeletonBox(width: 24, height: 24),
              ],
            ),
            const SizedBox(height: 14),
            ...List.generate(
              3,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: AppSkeletonBox(
                    height: 48,
                    borderRadius: BorderRadius.all(Radius.circular(10))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingEventTile extends StatelessWidget {
  const _UpcomingEventTile({
    required this.event,
    required this.accentColor,
    this.isFirst = false,
    this.isLast = false,
  });

  final CalendarEventWithShow event;
  final Color accentColor;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ce = event.calendarEvent;
    final season = event.season;

    final dt = ce.startDatetime.toLocal();
    final now = DateTime.now();

    final dateStr = '${_two(dt.day)}.${_two(dt.month)}.${dt.year}';

    // Status ermitteln
    final startOfToday = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(dt.year, dt.month, dt.day);

    final isPast = eventDay.isBefore(startOfToday);
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;

    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = dt.year == tomorrow.year &&
        dt.month == tomorrow.month &&
        dt.day == tomorrow.day;

    final weekdayStr = _getWeekdayName(dt.weekday);

    final seasonInfo = (season.seasonNumber != null && season.seasonNumber! > 0)
        ? 'S${season.seasonNumber}'
        : null;

    final streamOpt = (season.streamingOption ?? '').trim();
    final showEventId = ce.showEventId;
    final showId = ce.showId;
    final episodeInfo =
        ce.episodeNumber != null ? 'E${ce.episodeNumber}' : null;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        if (showEventId != null && showEventId.isNotEmpty) {
          context.push('${AppRoutes.showEventDetail}/$showEventId');
          return;
        }
        if (showId.isNotEmpty) {
          context.push('${AppRoutes.showOverview}/$showId');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              _DateBadge(
                text: dateStr,
                isToday: isToday,
                isTomorrow: isTomorrow,
                accentColor: accentColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    if (isPast)
                      _StatusBadge(
                        text: 'GELAUFEN',
                        color: const Color.fromARGB(60, 44, 44, 44),
                        textColor: const Color.fromARGB(255, 138, 138, 138),
                      )
                    else if (isToday)
                      _StatusBadge(
                        text: 'HEUTE',
                        color: accentColor,
                        textColor: Colors.black,
                      )
                    else if (isTomorrow)
                      _StatusBadge(text: 'MORGEN', color: Colors.white)
                    else
                      _StatusBadge(
                        text: weekdayStr.toUpperCase(),
                        color: Colors.white38,
                        textColor: const Color.fromARGB(255, 0, 0, 0),
                      ),
                    const SizedBox(width: 8),
                    // Text(
                    //   timeStr,
                    //   style: GoogleFonts.montserrat(
                    //     color: Colors.white,
                    //     fontSize: 12,
                    //     fontWeight: FontWeight.w700,
                    //   ),
                    // ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (seasonInfo != null)
                              _MetaPill(label: seasonInfo),
                            if (seasonInfo != null && episodeInfo != null)
                              const SizedBox(width: 6),
                            if (episodeInfo != null)
                              _MetaPill(label: episodeInfo),
                            if ((seasonInfo != null || episodeInfo != null) &&
                                streamOpt.isNotEmpty)
                              const SizedBox(width: 6),
                            if (streamOpt.isNotEmpty)
                              _MetaPill(
                                label: streamOpt,
                                textColor: accentColor,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.32),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  String _getWeekdayName(int weekday) {
    const weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return weekdays[weekday - 1];
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({
    required this.text,
    required this.accentColor,
    this.isToday = false,
    this.isTomorrow = false,
  });

  final String text;
  final Color accentColor;
  final bool isToday;
  final bool isTomorrow;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    if (isToday) {
      bgColor = accentColor;
      textColor = Colors.black;
    } else if (isTomorrow) {
      bgColor = Colors.black;
      textColor = Colors.white;
    } else {
      bgColor = Colors.black;
      textColor = Colors.white70;
    }

    return Container(
      width: 92,
      //padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: bgColor,
        //borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday ? accentColor : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: isToday || isTomorrow ? FontWeight.bold : FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.text,
    required this.color,
    this.textColor,
  });

  final String text;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.75),
        //borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: textColor ?? Colors.black,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.label,
    this.textColor,
  });

  final String label;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor ?? Colors.white70,
        ),
      ),
    );
  }
}
