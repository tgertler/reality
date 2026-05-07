import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/features/feed_management/data/models/feed_item.dart';
import 'feed_card_helpers.dart';
import 'package:google_fonts/google_fonts.dart';

class ComingThisWeekBlockFeedCard extends StatelessWidget {
  final FeedItem item;

  const ComingThisWeekBlockFeedCard({super.key, required this.item});

  static const _weekdayLabels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  String _dayKey(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  DateTime? _parseUtcTimestamp(dynamic raw) {
    if (raw == null) return null;

    if (raw is DateTime) {
      return raw.toLocal();
    }

    if (raw is num) {
      final value = raw.toInt();
      final milliseconds = value > 1000000000000 ? value : value * 1000;
      return DateTime.fromMillisecondsSinceEpoch(
        milliseconds,
        isUtc: true,
      ).toLocal();
    }

    final text = raw.toString().trim();
    if (text.isEmpty) return null;

    // Postgres timestamptz typically arrives as ISO text with timezone/offset.
    // Parse it directly first and then normalize to local time.
    final directParsed = DateTime.tryParse(text);
    if (directParsed != null) {
      return directParsed.toLocal();
    }

    final asInt = int.tryParse(text);
    if (asInt != null) {
      final milliseconds = asInt > 1000000000000 ? asInt : asInt * 1000;
      return DateTime.fromMillisecondsSinceEpoch(
        milliseconds,
        isUtc: true,
      ).toLocal();
    }

    // Fallback for rare payloads without explicit timezone: treat as UTC.
    final parsedAsUtc = DateTime.tryParse('${text}Z');
    return parsedAsUtc?.toLocal();
  }

  DateTime? _eventDateTime(Map<String, dynamic> entry) {
    return _parseUtcTimestamp(entry['datetime']) ??
        _parseUtcTimestamp(entry['start_datetime']) ??
        _parseUtcTimestamp(entry['feed_timestamp']);
  }

  Map<String, List<String>> _groupByDay(List<Map<String, dynamic>> items, DateTime weekStart) {
    final prepared = <({DateTime dt, String title, String dedupeKey})>[];
    for (final entry in items) {
      final dt = _eventDateTime(entry);
      if (dt == null) continue;

      final title = resolvePreferredShowTitle(entry, fallback: 'Unbekannt').trim();
      if (title.isEmpty) continue;

      final showId = entry['show_id']?.toString().trim();
      final dedupeKey = (showId != null && showId.isNotEmpty)
          ? showId
          : title.toLowerCase();

      prepared.add((dt: dt, title: title, dedupeKey: dedupeKey));
    }

    prepared.sort((a, b) => a.dt.compareTo(b.dt));

    final map = <String, List<String>>{};
    final seenByDay = <String, Set<String>>{};

    for (final item in prepared) {
      final dayDate = DateTime(item.dt.year, item.dt.month, item.dt.day);
      final diff = dayDate.difference(weekStart).inDays;
      if (diff < 0 || diff > 6) continue;

      final key = _dayKey(dayDate);
      final seen = seenByDay.putIfAbsent(key, () => <String>{});
      if (!seen.add(item.dedupeKey)) continue;

      map.putIfAbsent(key, () => <String>[]);
      map[key]!.add(item.title);
    }

    return map;
  }

  @override
  Widget build(BuildContext context) {
    final items = parseFeedItems(item.data['items']);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final showsByDay = _groupByDay(items, today);

    return Padding(
      padding: EdgeInsets.zero,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: const BoxDecoration(
          color: Colors.white,

        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Container(
              //   padding:
              //       const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              //   decoration: const BoxDecoration(
              //     color: AppColors.pop,
              //     border: Border.fromBorderSide(
              //       BorderSide(color: Colors.black, width: 2),
              //     ),
              //   ),
              //   child: Text(
              //     'DIESE WOCHE',
              //     style: GoogleFonts.dmSans(
              //       color: Colors.black,
              //       fontSize: 11,
              //       fontWeight: FontWeight.w900,
              //       letterSpacing: 0.8,
              //     ),
              //   ),
              // ),
              Text(
                'WAS GEHT',
                style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontSize: 44,
                  height: 0.95,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'DIE WOCHE?',
                style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontSize: 44,
                  height: 0.95,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 12),
              // Container(
              //   width: 116,
              //   height: 8,
              //   color: AppColors.pop,
              // ),
              //const SizedBox(height: 14),
              Text(
                'Die Auslastung der nächsten 7 Tage:',
                style: GoogleFonts.dmSans(
                  color: Colors.black54,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (i) {
                    final dayDate = today.add(Duration(days: i));
                    final weekdayIndex = dayDate.weekday - 1;
                    final key = _dayKey(dayDate);
                    final shows = showsByDay[key] ?? [];
                    return _DayRow(
                      dayLabel: _weekdayLabels[weekdayIndex],
                      shows: shows,
                      isToday: i == 0,
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

// ─── Day Row ──────────────────────────────────────────────────────────────────

class _DayRow extends StatelessWidget {
  final String dayLabel;
  final List<String> shows;
  final bool isToday;

  static const _maxSegments = 5;

  const _DayRow({
    required this.dayLabel,
    required this.shows,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    final count = shows.length.clamp(0, _maxSegments);
    final isEmpty = shows.isEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isToday ? AppColors.pop : const Color(0xFFF1F1F1),
        border: Border.all(
          color: Colors.black,
          width: isToday ? 2 : 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(3, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 26,
            child: Text(
              dayLabel,
              style: GoogleFonts.montserrat(
                color: isToday ? Colors.black : Colors.black87,
                fontSize: 13,
                fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Row(
            children: List.generate(_maxSegments, (i) {
              final filled = i < count;
              return Container(
                margin: const EdgeInsets.only(right: 3),
                width: 14,
                height: 18,
                decoration: BoxDecoration(
                  color: filled
                      ? Colors.black.withValues(alpha: 0.75)
                      : Colors.black.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.black, width: 1),
                ),
              );
            }),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isEmpty ? 'Nichts los' : shows.join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                color: isEmpty ? Colors.black38 : Colors.black87,
                fontSize: 13,
                fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
