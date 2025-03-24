import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/features/calendar_management/presentation/providers/show_events_provider.dart';
import 'package:frontend/core/utils/streaming_service_logo.dart';

class NextCalendarEventWidget extends ConsumerStatefulWidget {
  final String showId;

  const NextCalendarEventWidget({super.key, required this.showId});

  @override
  ConsumerState<NextCalendarEventWidget> createState() =>
      _NextCalendarEventWidgetState();
}

class _NextCalendarEventWidgetState
    extends ConsumerState<NextCalendarEventWidget> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(showEventsProvider.notifier).fetchNextEvent(widget.showId);
    });
  }

  @override
  void didUpdateWidget(covariant NextCalendarEventWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showId != widget.showId) {
      ref.read(showEventsProvider.notifier).fetchNextEvent(widget.showId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(showEventsProvider);
    final nextEvent = state.nextEvent;

    if (state.isLoadingNext && nextEvent == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color.fromARGB(255, 29, 29, 29),
        ),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (nextEvent == null) {
      return const SizedBox.shrink();
    }

    final ce = nextEvent.calendarEvent;
    final season = nextEvent.season;
    final dt = ce.startDatetime?.toLocal();
    final dateStr = dt != null
        ? '${_two(dt.day)}.${_two(dt.month)}.${dt.year}'
        : 'Unbekannt';

    // Prüfen ob heute
    final now = DateTime.now();
    final isToday = dt != null &&
        dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;

    final seasonInfo = (season.seasonNumber != null && season.seasonNumber! > 0)
        ? 'S${season.seasonNumber}'
        : null;
    final streamOpt = (season.streamingOption ?? '').trim();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color.fromARGB(255, 45, 45, 45),
        border: isToday
            ? Border.all(color: Colors.greenAccent.withOpacity(0.5), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isToday
                  ? Colors.greenAccent.withOpacity(0.2)
                  : const Color.fromARGB(255, 66, 66, 66),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.event_available,
              color: isToday ? Colors.greenAccent : Colors.white70,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Nächstes Event',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white54,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HEUTE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (seasonInfo != null) ...[
                      const Text(
                        ' • ',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      Text(
                        seasonInfo,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Streaming Logo
          if (streamOpt.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              width: 70,
              height: 40,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: SvgPicture.asset(
                  getStreamingServiceLogo(streamOpt),
                  allowDrawingOutsideViewBox: true,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _two(int v) => v.toString().padLeft(2, '0');
}
