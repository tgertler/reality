import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/features/show_management/show_discovery/domain/entities/show.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

List<Show> selectUpcomingReleaseWindowShows(
  List<Show> shows, {
  DateTime? now,
  int limit = 8,
}) {
  final reference = now ?? DateTime.now();
  final startOfMonth = DateTime(reference.year, reference.month, 1);

  final candidates = shows
      .map((show) => _ReleaseWindowCandidate.fromShow(show, reference))
      .whereType<_ReleaseWindowCandidate>()
      .where((candidate) =>
          candidate.windowEnd == null ||
          !candidate.windowEnd!.isBefore(startOfMonth))
      .toList()
    ..sort((a, b) {
      final aDate = a.sortDate;
      final bDate = b.sortDate;
      if (aDate != null && bDate != null) {
        final compare = aDate.compareTo(bDate);
        if (compare != 0) return compare;
      } else if (aDate != null) {
        return -1;
      } else if (bDate != null) {
        return 1;
      }
      return a.show.displayTitle
          .toLowerCase()
          .compareTo(b.show.displayTitle.toLowerCase());
    });

  final result = <Show>[];
  final seen = <String>{};
  for (final candidate in candidates) {
    if (seen.add(candidate.show.id)) {
      result.add(candidate.show);
    }
    if (result.length >= limit) {
      break;
    }
  }

  return result;
}

class ReleaseWindowHomeSectionWidget extends StatelessWidget {
  final List<Show> shows;
  final bool showHeader;

  const ReleaseWindowHomeSectionWidget({
    super.key,
    required this.shows,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    if (shows.isEmpty) {
      return const SizedBox.shrink();
    }

    final featuredShow = shows.first;
    final secondaryShows = shows.skip(1).take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              color: Colors.black,
              child: Text(
                '🤔 TEASER',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Was bald kommen könnte',
              style: GoogleFonts.montserrat(
                color: const Color(0xFF1E1E1E),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Schätzung auf Basis von unseren Erfahrungen',
          style: GoogleFonts.dmSans(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        ],
        _FeaturedReleaseWindowCard(show: featuredShow),
        if (secondaryShows.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...secondaryShows.map(
            (show) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ReleaseWindowListCard(show: show),
            ),
          ),
        ],
      ],
    );
  }
}

class _FeaturedReleaseWindowCard extends StatelessWidget {
  final Show show;

  const _FeaturedReleaseWindowCard({required this.show});

  @override
  Widget build(BuildContext context) {
    final presentation = _buildReleaseWindowPresentation(show.releaseWindow);
    final genre = show.genre?.trim() ?? '';

    return GestureDetector(
      onTap: () => context.push('${AppRoutes.showOverview}/${show.id}'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        color: Colors.black,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: AppColors.pop,
                  child: Text(
                    presentation.badge,
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.north_east_rounded,
                  color: AppColors.pop,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              show.displayTitle.isEmpty ? 'Unbekannte Show' : show.displayTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              presentation.subtitle,
              style: GoogleFonts.dmSans(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (genre.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                genre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReleaseWindowListCard extends StatelessWidget {
  final Show show;

  const _ReleaseWindowListCard({required this.show});

  @override
  Widget build(BuildContext context) {
    final presentation = _buildReleaseWindowPresentation(show.releaseWindow);

    return GestureDetector(
      onTap: () => context.push('${AppRoutes.showOverview}/${show.id}'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: Colors.black,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              color: Colors.white.withValues(alpha: 0.06),
              child: Text(
                presentation.emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    show.displayTitle.isEmpty
                        ? 'Unbekannte Show'
                        : show.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    presentation.badge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: AppColors.pop,
            ),
          ],
        ),
      ),
    );
  }
}

_ReleaseWindowPresentation _buildReleaseWindowPresentation(String? rawValue) {
  final raw = rawValue?.trim() ?? '';
  if (raw.isEmpty) {
    return const _ReleaseWindowPresentation(
      emoji: '✨',
      badge: 'Bald',
      subtitle: 'Release-Fenster bereits angeteasert',
    );
  }

  final normalized = raw.toLowerCase().replaceAll('_', '-');
  final yearMatch = RegExp(r'(20\d{2})').firstMatch(normalized);
  final year = yearMatch?.group(1);

  if (normalized.contains('spring') ||
      normalized.contains('frühling') ||
      normalized.contains('fruehling')) {
    return _ReleaseWindowPresentation(
      emoji: '🌸',
      badge: year == null ? 'Frühling' : 'Frühling $year',
      subtitle: 'Frisches Release im Frühjahr',
    );
  }
  if (normalized.contains('summer') || normalized.contains('sommer')) {
    return _ReleaseWindowPresentation(
      emoji: '☀️',
      badge: year == null ? 'Sommer' : 'Sommer $year',
      subtitle: 'Heißer Kandidat für den Sommer',
    );
  }
  if (normalized.contains('autumn') ||
      normalized.contains('fall') ||
      normalized.contains('herbst')) {
    return _ReleaseWindowPresentation(
      emoji: '🍂',
      badge: year == null ? 'Herbst' : 'Herbst $year',
      subtitle: 'Im Herbst könnte es losgehen',
    );
  }
  if (normalized.contains('winter')) {
    return _ReleaseWindowPresentation(
      emoji: '❄️',
      badge: year == null ? 'Winter' : 'Winter $year',
      subtitle: 'Kalter Slot, heiß erwartet',
    );
  }

  final quarterMatch = RegExp(r'q\s*([1-4])').firstMatch(normalized);
  if (quarterMatch != null) {
    final quarter = quarterMatch.group(1)!;
    return _ReleaseWindowPresentation(
      emoji: '🗓️',
      badge: year == null ? 'Q$quarter' : 'Q$quarter $year',
      subtitle: 'Eingeordnet nach Quartal',
    );
  }

  final monthMatch = RegExp(r'^(20\d{2})-(\d{1,2})$').firstMatch(normalized);
  if (monthMatch != null) {
    final parsedYear = monthMatch.group(1)!;
    final parsedMonth = int.tryParse(monthMatch.group(2)!);
    final monthName = parsedMonth == null ? null : _monthName(parsedMonth);
    if (monthName != null && monthName != 'Monat') {
      return _ReleaseWindowPresentation(
        emoji: '🗓️',
        badge: '$monthName $parsedYear',
        subtitle: 'Monatlich eingegrenztes Release Window',
      );
    }
  }

  if (RegExp(r'^(20\d{2})$').hasMatch(normalized)) {
    return _ReleaseWindowPresentation(
      emoji: '🪩',
      badge: year ?? raw,
      subtitle: 'Im Laufe des Jahres im Blick behalten',
    );
  }

  return _ReleaseWindowPresentation(
    emoji: '✨',
    badge: raw.replaceAll('-', ' · '),
    subtitle: 'Release Window bereits hinterlegt',
  );
}

String _monthName(int month) {
  const monthNames = <int, String>{
    1: 'Januar',
    2: 'Februar',
    3: 'März',
    4: 'April',
    5: 'Mai',
    6: 'Juni',
    7: 'Juli',
    8: 'August',
    9: 'September',
    10: 'Oktober',
    11: 'November',
    12: 'Dezember',
  };
  return monthNames[month] ?? 'Monat';
}

class _ReleaseWindowPresentation {
  final String emoji;
  final String badge;
  final String subtitle;

  const _ReleaseWindowPresentation({
    required this.emoji,
    required this.badge,
    required this.subtitle,
  });
}

class _ReleaseWindowCandidate {
  final Show show;
  final DateTime? sortDate;
  final DateTime? windowEnd;

  const _ReleaseWindowCandidate({
    required this.show,
    required this.sortDate,
    required this.windowEnd,
  });

  static _ReleaseWindowCandidate? fromShow(Show show, DateTime reference) {
    final raw = show.releaseWindow?.trim();
    if (raw == null || raw.isEmpty) return null;

    final normalized = raw.toLowerCase().replaceAll('_', '-');
    if (normalized.contains('archiv') ||
        normalized.contains('abgeschlossen') ||
        normalized.contains('beendet')) {
      return null;
    }

    final estimatedWindow = _estimateWindow(normalized, reference);
    final hasUpcomingKeyword = _containsUpcomingKeyword(normalized);
    final hasFutureYear = _extractYear(normalized) >= reference.year;

    if (estimatedWindow == null && !hasUpcomingKeyword && !hasFutureYear) {
      return null;
    }

    return _ReleaseWindowCandidate(
      show: show,
      sortDate: estimatedWindow?.start,
      windowEnd: estimatedWindow?.end,
    );
  }

  static bool _containsUpcomingKeyword(String raw) {
    return raw.contains('bald') ||
        raw.contains('coming soon') ||
        raw.contains('demnächst') ||
        raw.contains('next') ||
        raw.contains('soon') ||
        raw.contains('heute') ||
        raw.contains('morgen') ||
        raw.contains('diese woche') ||
        raw.contains('nächste woche') ||
        raw.contains('q1') ||
        raw.contains('q2') ||
        raw.contains('q3') ||
        raw.contains('q4') ||
        raw.contains('frühling') ||
        raw.contains('sommer') ||
        raw.contains('herbst') ||
        raw.contains('winter');
  }

  static int _extractYear(String raw) {
    final match = RegExp(r'(20\d{2})').firstMatch(raw);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  static _ReleaseWindowRange? _estimateWindow(String raw, DateTime reference) {
    if (raw.contains('heute')) {
      final day = DateTime(reference.year, reference.month, reference.day);
      return _ReleaseWindowRange(start: day, end: day);
    }
    if (raw.contains('morgen')) {
      final tomorrow = reference.add(const Duration(days: 1));
      final day = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      return _ReleaseWindowRange(start: day, end: day);
    }
    if (raw.contains('diese woche')) {
      return _ReleaseWindowRange(
        start: DateTime(reference.year, reference.month, reference.day),
        end: DateTime(reference.year, reference.month, reference.day + 6),
      );
    }
    if (raw.contains('nächste woche') || raw.contains('naechste woche')) {
      final start =
          DateTime(reference.year, reference.month, reference.day + 7);
      return _ReleaseWindowRange(
        start: start,
        end: DateTime(start.year, start.month, start.day + 6),
      );
    }
    if (raw.contains('bald') ||
        raw.contains('demnächst') ||
        raw.contains('demnaechst') ||
        raw.contains('coming soon')) {
      final start =
          DateTime(reference.year, reference.month, reference.day + 7);
      return _ReleaseWindowRange(
        start: start,
        end: DateTime(start.year, start.month, start.day + 30),
      );
    }

    final yearOnlyMatch = RegExp(r'^(20\d{2})$').firstMatch(raw);
    if (yearOnlyMatch != null) {
      final year = int.parse(yearOnlyMatch.group(1)!);
      return _ReleaseWindowRange(
        start: DateTime(year, 7, 1),
        end: DateTime(year, 12, 31, 23, 59, 59),
      );
    }

    final yearMonthMatch = RegExp(r'^(20\d{2})-(\d{1,2})$').firstMatch(raw);
    if (yearMonthMatch != null) {
      final year = int.parse(yearMonthMatch.group(1)!);
      final month = int.parse(yearMonthMatch.group(2)!);
      if (month >= 1 && month <= 12) {
        return _monthWindow(year, month);
      }
    }

    final year = _extractYear(raw);
    final effectiveYear = year == 0 ? reference.year : year;

    final quarterMatch = RegExp(r'q\s*([1-4])').firstMatch(raw);
    if (quarterMatch != null) {
      final quarter = int.tryParse(quarterMatch.group(1) ?? '1') ?? 1;
      final startMonth = ((quarter - 1) * 3) + 1;
      return _ReleaseWindowRange(
        start: DateTime(effectiveYear, startMonth, 1),
        end: DateTime(effectiveYear, startMonth + 3, 0, 23, 59, 59),
      );
    }

    final seasonWindow = _seasonWindow(raw, effectiveYear);
    if (seasonWindow != null) {
      return seasonWindow;
    }

    const months = {
      'januar': 1,
      'jan': 1,
      'februar': 2,
      'february': 2,
      'feb': 2,
      'märz': 3,
      'maerz': 3,
      'march': 3,
      'april': 4,
      'mai': 5,
      'may': 5,
      'juni': 6,
      'june': 6,
      'juli': 7,
      'july': 7,
      'august': 8,
      'september': 9,
      'sept': 9,
      'oktober': 10,
      'october': 10,
      'okt': 10,
      'november': 11,
      'nov': 11,
      'dezember': 12,
      'december': 12,
      'dez': 12,
      'dec': 12,
    };

    for (final entry in months.entries) {
      if (raw.contains(entry.key)) {
        var targetYear = effectiveYear;
        final candidate = DateTime(targetYear, entry.value, 1);
        if (year == 0 &&
            candidate.isBefore(DateTime(reference.year, reference.month, 1))) {
          targetYear += 1;
        }
        return _monthWindow(targetYear, entry.value);
      }
    }

    return null;
  }

  static _ReleaseWindowRange? _seasonWindow(String raw, int year) {
    if (raw.contains('frühling') ||
        raw.contains('fruehling') ||
        raw.contains('spring')) {
      return _ReleaseWindowRange(
        start: DateTime(year, 3, 1),
        end: DateTime(year, 5, 31, 23, 59, 59),
      );
    }
    if (raw.contains('sommer') || raw.contains('summer')) {
      return _ReleaseWindowRange(
        start: DateTime(year, 6, 1),
        end: DateTime(year, 8, 31, 23, 59, 59),
      );
    }
    if (raw.contains('herbst') ||
        raw.contains('autumn') ||
        raw.contains('fall')) {
      return _ReleaseWindowRange(
        start: DateTime(year, 9, 1),
        end: DateTime(year, 11, 30, 23, 59, 59),
      );
    }
    if (raw.contains('winter')) {
      return _ReleaseWindowRange(
        start: DateTime(year, 12, 1),
        end: DateTime(year + 1, 2, 28, 23, 59, 59),
      );
    }
    return null;
  }

  static _ReleaseWindowRange _monthWindow(int year, int month) {
    return _ReleaseWindowRange(
      start: DateTime(year, month, 1),
      end: DateTime(year, month + 1, 0, 23, 59, 59),
    );
  }
}

class _ReleaseWindowRange {
  final DateTime start;
  final DateTime end;

  const _ReleaseWindowRange({
    required this.start,
    required this.end,
  });
}
