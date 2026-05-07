import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReleaseWindowWidget extends StatelessWidget {
  final String releaseWindow;
  final Color accentColor;

  const ReleaseWindowWidget({
    super.key,
    required this.releaseWindow,
    this.accentColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = _parseReleaseWindow(releaseWindow);
    if (parsed == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Container(
        color: const Color(0xFF111111),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.schedule,
              size: 14,
              color: accentColor.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 6),
            Text(
              'Kommendes Release:',
              style: GoogleFonts.dmSans(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              _leadingIcon(parsed),
              size: 14,
              color: accentColor.withValues(alpha: 0.95),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                parsed.year == null ? parsed.label : '${parsed.label} ${parsed.year}',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => _showInfoDialog(context),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.white60,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _leadingIcon(_ParsedReleaseWindow parsed) {
    if (parsed.type == _ReleaseWindowType.month) {
      return Icons.calendar_month;
    }

    switch (parsed.season!) {
      case _Season.spring:
        return Icons.local_florist;
      case _Season.summer:
        return Icons.wb_sunny;
      case _Season.autumn:
        return Icons.park;
      case _Season.winter:
        return Icons.ac_unit;
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Info'),
        content: const Text(
          'Dieser Zeitraum ist geschaetzt und kann sich noch aendern. '
          'Je nach Datenlage ist nur die Jahreszeit oder bereits ein Monat bekannt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

enum _ReleaseWindowType { month, season }

class _ParsedReleaseWindow {
  final _ReleaseWindowType type;
  final int? year;
  final int? month;
  final _Season? season;
  final String label;

  const _ParsedReleaseWindow.month({
    required this.month,
    required this.label,
    this.year,
  })  : type = _ReleaseWindowType.month,
        season = null;

  const _ParsedReleaseWindow.season({
    required this.season,
    required this.label,
    this.year,
  })  : type = _ReleaseWindowType.season,
        month = null;
}

enum _Season { spring, summer, autumn, winter }

_ParsedReleaseWindow? _parseReleaseWindow(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;

  final lower = value.toLowerCase().replaceAll('_', '-');

  final ym = RegExp(r'^(\d{4})-(\d{1,2})$').firstMatch(lower);
  if (ym != null) {
    final year = int.tryParse(ym.group(1)!);
    final month = int.tryParse(ym.group(2)!);
    if (year != null && month != null && month >= 1 && month <= 12) {
      return _ParsedReleaseWindow.month(
        year: year,
        month: month,
        label: _monthName(month),
      );
    }
  }

  final seasonHyphen = RegExp(
    r'^(\d{4})-(spring|summer|autumn|fall|winter|fruehling|fruhling|sommer|herbst)$',
  ).firstMatch(lower);
  if (seasonHyphen != null) {
    final year = int.tryParse(seasonHyphen.group(1)!);
    final seasonToken = seasonHyphen.group(2)!;
    final season = _seasonFromToken(seasonToken);
    if (season != null) {
      return _ParsedReleaseWindow.season(
        year: year,
        season: season,
        label: _seasonLabel(season),
      );
    }
  }

  final monthText = _monthFromText(lower);
  if (monthText != null) {
    final year = RegExp(r'\b(19\d{2}|20\d{2}|21\d{2})\b')
        .firstMatch(lower)
        ?.group(1);
    return _ParsedReleaseWindow.month(
      year: year == null ? null : int.tryParse(year),
      month: monthText,
      label: _monthName(monthText),
    );
  }

  final seasonText = _seasonFromText(lower);
  if (seasonText != null) {
    final year = RegExp(r'\b(19\d{2}|20\d{2}|21\d{2})\b')
        .firstMatch(lower)
        ?.group(1);
    return _ParsedReleaseWindow.season(
      year: year == null ? null : int.tryParse(year),
      season: seasonText,
      label: _seasonLabel(seasonText),
    );
  }

  return null;
}

int? _monthFromText(String lower) {
  const months = <String, int>{
    'january': 1,
    'januar': 1,
    'jan': 1,
    'february': 2,
    'februar': 2,
    'feb': 2,
    'march': 3,
    'maerz': 3,
    'märz': 3,
    'marz': 3,
    'mar': 3,
    'april': 4,
    'apr': 4,
    'may': 5,
    'mai': 5,
    'june': 6,
    'juni': 6,
    'jun': 6,
    'july': 7,
    'juli': 7,
    'jul': 7,
    'august': 8,
    'aug': 8,
    'september': 9,
    'sep': 9,
    'sept': 9,
    'october': 10,
    'oktober': 10,
    'oct': 10,
    'okt': 10,
    'november': 11,
    'nov': 11,
    'december': 12,
    'dezember': 12,
    'dec': 12,
    'dez': 12,
  };

  for (final entry in months.entries) {
    if (lower.contains(entry.key)) {
      return entry.value;
    }
  }
  return null;
}

_Season? _seasonFromToken(String token) {
  switch (token) {
    case 'spring':
    case 'fruehling':
    case 'fruhling':
      return _Season.spring;
    case 'summer':
    case 'sommer':
      return _Season.summer;
    case 'autumn':
    case 'fall':
    case 'herbst':
      return _Season.autumn;
    case 'winter':
      return _Season.winter;
    default:
      return null;
  }
}

_Season? _seasonFromText(String lower) {
  if (lower.contains('spring') ||
      lower.contains('fruehling') ||
      lower.contains('fruhling')) {
    return _Season.spring;
  }
  if (lower.contains('summer') || lower.contains('sommer')) {
    return _Season.summer;
  }
  if (lower.contains('autumn') ||
      lower.contains('fall') ||
      lower.contains('herbst')) {
    return _Season.autumn;
  }
  if (lower.contains('winter')) {
    return _Season.winter;
  }
  return null;
}

String _monthName(int month) {
  const monthNames = <int, String>{
    1: 'Januar',
    2: 'Februar',
    3: 'Marz',
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

String _seasonLabel(_Season season) {
  switch (season) {
    case _Season.spring:
      return 'Frühling';
    case _Season.summer:
      return 'Sommer';
    case _Season.autumn:
      return 'Herbst';
    case _Season.winter:
      return 'Winter';
  }
}
