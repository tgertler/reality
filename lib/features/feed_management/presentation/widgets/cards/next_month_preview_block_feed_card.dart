import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/features/feed_management/data/models/feed_item.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/feed_card_helpers.dart';
import 'package:google_fonts/google_fonts.dart';

class NextMonthPreviewBlockFeedCard extends StatelessWidget {
  final FeedItem item;

  const NextMonthPreviewBlockFeedCard({super.key, required this.item});

  static const _monthNames = [
    '',
    'JANUAR',
    'FEBRUAR',
    'MÄRZ',
    'APRIL',
    'MAI',
    'JUNI',
    'JULI',
    'AUGUST',
    'SEPTEMBER',
    'OKTOBER',
    'NOVEMBER',
    'DEZEMBER',
  ];

  String? _themeKey(String title) {
    final t = title.toLowerCase();
    if (t.contains('love') ||
        t.contains('island') ||
        t.contains('dating') ||
        t.contains('bachelor') ||
        t.contains('temptation') ||
        t.contains('paradise') ||
        t.contains('kiss') ||
        t.contains('flirt') ||
        t.contains('date')) {
      return 'dating';
    }
    if (t.contains('gntm') ||
        t.contains('fashion') ||
        t.contains('model') ||
        t.contains('style') ||
        t.contains('runway') ||
        t.contains('heidi')) {
      return 'fashion';
    }
    if (t.contains('traitor') ||
        t.contains('challenge') ||
        t.contains('survivor') ||
        t.contains('game') ||
        t.contains('master') ||
        t.contains('secret') ||
        t.contains('mission') ||
        t.contains('strateg')) {
      return 'games';
    }
    if (t.contains('elite') ||
        t.contains('house') ||
        t.contains('villa') ||
        t.contains('drama') ||
        t.contains('reunion') ||
        t.contains('talk') ||
        t.contains('real')) {
      return 'drama';
    }
    return null;
  }

  static const _themeData = {
    'dating': (emoji: '❤️', label: 'Dating & Drama'),
    'fashion': (emoji: '👗', label: 'Fashion & Shows'),
    'games': (emoji: '🎭', label: 'Games & Secrets'),
    'drama': (emoji: '🔥', label: 'Drama & Reality'),
    'misc': (emoji: '⭐', label: 'Weitere Highlights'),
  };

  @override
  Widget build(BuildContext context) {
    final items = parseFeedItems(item.data['items']);

    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    DateTime? refDate;
    for (final e in items) {
      final dt = DateTime.tryParse(e['datetime']?.toString() ?? '')?.toLocal();
      if (dt != null) {
        refDate = dt;
        break;
      }
    }
    final targetMonth =
        refDate != null ? DateTime(refDate.year, refDate.month, 1) : nextMonth;
    final monthLabel = _monthNames[targetMonth.month];

    // Group items into themes (max 2 per theme, max 3 themes)
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final e in items) {
      final dt = DateTime.tryParse(e['datetime']?.toString() ?? '')?.toLocal();
      if (dt != null &&
          (dt.year != targetMonth.year || dt.month != targetMonth.month)) {
        continue;
      }
      final title = resolvePreferredShowTitle(e, fallback: 'Unbekannt');
      final key = _themeKey(title) ?? 'misc';
      grouped.putIfAbsent(key, () => []);
      if (grouped[key]!.length < 2) grouped[key]!.add(e);
    }

    const preferredOrder = ['dating', 'fashion', 'games', 'drama', 'misc'];
    final themes = preferredOrder
        .where((k) => grouped.containsKey(k))
        .take(3)
        .map((k) => (key: k, entries: grouped[k]!))
        .toList();

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
              // Linker Pop-Randbalken an der Headline (Varianz 5)
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.pop, width: 5),
                  ),
                ),
                padding: const EdgeInsets.only(left: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAS KOMMT',
                      style: GoogleFonts.montserrat(
                        color: Colors.black,
                        fontSize: 44,
                        height: 0.95,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                      ),
                    ),
                    Text(
                      'IM $monthLabel',
                      style: GoogleFonts.montserrat(
                        color: AppColors.pop,
                        fontSize: 44,
                        height: 0.95,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (themes.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'Keine Vorschau verfügbar.',
                      style: GoogleFonts.dmSans(
                        color: Colors.black45,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < themes.length; i++) ...[
                        if (i > 0) const SizedBox(height: 30),
                        _ThemeSection(
                          emoji: _themeData[themes[i].key]!.emoji,
                          label: _themeData[themes[i].key]!.label,
                          entries: themes[i].entries,
                          accent: AppColors.pop,
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

}

// ─── Theme Section ────────────────────────────────────────────────────────────

class _ThemeSection extends StatelessWidget {
  final String emoji;
  final String label;
  final List<Map<String, dynamic>> entries;
  final Color accent;

  const _ThemeSection({
    required this.emoji,
    required this.label,
    required this.entries,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 14),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.montserrat(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Show tile
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF1F1F1),
            border: Border.fromBorderSide(
              BorderSide(color: Colors.black, width: 1.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                offset: Offset(3, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.map((e) {
              final title = resolvePreferredShowTitle(e, fallback: 'Unbekannt');
              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(right: 8, top: 1),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
