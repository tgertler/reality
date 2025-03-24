import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/calendar_management/domain/entities/calendar_event_with_show.dart';
import 'package:frontend/features/calendar_management/presentation/providers/show_events_provider.dart';

class UpcomingCalendarEventsListWidget extends ConsumerStatefulWidget {
  const UpcomingCalendarEventsListWidget({
    super.key,
    required this.showId,
    this.maxItems,
  });

  final String showId;
  final int? maxItems;

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
      setState(() => _isExpanded = false);
      ref.read(showEventsProvider.notifier).fetchUpcomingEvents(widget.showId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(showEventsProvider);
    final isLoading = state.isLoadingUpcoming && state.upcomingEvents.isEmpty;

    final allEvents = state.upcomingEvents;
    final nextEvent = state.nextEvent;
    final filteredEvents = allEvents
        .where((e) =>
            nextEvent == null ||
            e.calendarEvent.calendarEventId !=
                nextEvent.calendarEvent.calendarEventId)
        .toList();

    final events = widget.maxItems == null
        ? filteredEvents
        : filteredEvents.take(widget.maxItems!).toList();

    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
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
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_note,
                      color: Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Weitere Events',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 66, 66, 66),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${events.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
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
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                bottom: 12.0,
              ),
              child: Column(
                children: [
                  if (state.errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: events.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 12,
                        thickness: 0.5,
                        color: Color.fromARGB(255, 66, 66, 66),
                      ),
                      itemBuilder: (_, i) => _UpcomingEventTile(
                        event: events[i],
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
    );
  }
}

class _UpcomingEventTile extends StatelessWidget {
  const _UpcomingEventTile({
    required this.event,
    this.isFirst = false,
    this.isLast = false,
  });

  final CalendarEventWithShow event;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ce = event.calendarEvent;
    final season = event.season;

    final dt = ce.startDatetime?.toLocal();
    final now = DateTime.now();

    final dateStr = dt != null
        ? '${_two(dt.day)}.${_two(dt.month)}.${dt.year}'
        : 'Unbekannt';

    // Status ermitteln
    final isToday = dt != null &&
        dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;

    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = dt != null &&
        dt.year == tomorrow.year &&
        dt.month == tomorrow.month &&
        dt.day == tomorrow.day;

    final weekdayStr = dt != null ? _getWeekdayName(dt.weekday) : null;

    final seasonInfo = (season.seasonNumber != null && season.seasonNumber! > 0)
        ? 'S${season.seasonNumber}'
        : null;

    final streamOpt = (season.streamingOption ?? '').trim();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          // Datum Badge
          _DateBadge(
            text: dateStr,
            isToday: isToday,
            isTomorrow: isTomorrow,
          ),
          const SizedBox(width: 12),
          // Alle Infos in einer Zeile
          Expanded(
            child: Row(
              children: [
                // Status Badge
                if (isToday)
                  _StatusBadge(text: 'HEUTE', color: Colors.greenAccent)
                else if (isTomorrow)
                  _StatusBadge(text: 'MORGEN', color: Colors.orangeAccent)
                else if (weekdayStr != null)
                  _StatusBadge(
                    text: weekdayStr.toUpperCase(),
                    color: Colors.blueAccent,
                    textColor: Colors.white,
                  ),
                const SizedBox(width: 8),
                // Staffel
                if (seasonInfo != null) ...[
                  Text(
                    seasonInfo,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (streamOpt.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(color: Colors.white38)),
                    const SizedBox(width: 6),
                  ],
                ],
                // Streaming
                if (streamOpt.isNotEmpty)
                  Flexible(
                    child: Text(
                      streamOpt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
    this.isToday = false,
    this.isTomorrow = false,
  });

  final String text;
  final bool isToday;
  final bool isTomorrow;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Color? borderColor;

    if (isToday) {
      bgColor = Colors.greenAccent.withOpacity(0.15);
      textColor = Colors.greenAccent;
      borderColor = Colors.greenAccent.withOpacity(0.3);
    } else if (isTomorrow) {
      bgColor = Colors.orangeAccent.withOpacity(0.15);
      textColor = Colors.orangeAccent;
      borderColor = Colors.orangeAccent.withOpacity(0.3);
    } else {
      bgColor = const Color.fromARGB(255, 45, 45, 45);
      textColor = Colors.white70;
      borderColor = null;
    }

    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1)
            : null,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: isToday || isTomorrow ? FontWeight.bold : FontWeight.w500,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: textColor ?? color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
