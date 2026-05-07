import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/features/feed_management/data/models/feed_item.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/feed_card_helpers.dart';
import 'package:google_fonts/google_fonts.dart';

class MonthlyOverviewBlockFeedCard extends StatelessWidget {
  final FeedItem item;

  const MonthlyOverviewBlockFeedCard({super.key, required this.item});

  static const _accentColor = Color(0xFF3BCF8E);

  ({String emoji, String label}) _momentMeta(Map<String, dynamic> entry) {
    final type = entry['event_type']?.toString().toLowerCase() ?? '';
    if (type == 'finale') return (emoji: '🔥', label: 'Finale');
    if (type == 'premiere') return (emoji: '⭐', label: 'Premiere');
    if (type == 'reunion') return (emoji: '🤝', label: 'Reunion');
    return (emoji: '▶️', label: 'Neue Folge');
  }

  bool _isBigMoment(Map<String, dynamic> entry) {
    final type = entry['event_type']?.toString().toLowerCase() ?? '';
    return type == 'finale' || type == 'premiere' || type == 'reunion';
  }

  static const _deMonths = [
    '',
    'Jan',
    'Feb',
    'Mär',
    'Apr',
    'Mai',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Okt',
    'Nov',
    'Dez',
  ];

  String _shortDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '';
    return '${dt.day}. ${_deMonths[dt.month]}';
  }

  @override
  Widget build(BuildContext context) {
    final items = parseFeedItems(item.data['items']);

    // Determine target month
    DateTime? refDate;
    for (final entry in items) {
      final dt =
          DateTime.tryParse(entry['datetime']?.toString() ?? '')?.toLocal();
      if (dt != null) {
        refDate = dt;
        break;
      }
    }
    refDate ??= DateTime.now().add(const Duration(days: 30));
    final targetMonth = DateTime(refDate.year, refDate.month, 1);

    // Split: big moments first (max 5), rest → recurring
    final monthItems = items.where((e) {
      final dt = DateTime.tryParse(e['datetime']?.toString() ?? '')?.toLocal();
      return dt != null &&
          dt.year == targetMonth.year &&
          dt.month == targetMonth.month;
    }).toList();

    final bigMoments =
        monthItems.where((e) => _isBigMoment(e)).take(5).toList();
    final fillerCount = (5 - bigMoments.length).clamp(0, 5);
    if (fillerCount > 0) {
      final filler =
          monthItems.where((e) => !_isBigMoment(e)).take(fillerCount);
      bigMoments.addAll(filler);
    }

    // Recurring: titles not in bigMoments, deduplicated
    final bigTitles = bigMoments
        .map((e) => resolvePreferredShowTitle(e, fallback: ''))
        .toSet();
    final recurringTitles = <String>{};
    for (final e in monthItems) {
      final t = resolvePreferredShowTitle(e, fallback: '');
      if (!bigTitles.contains(t)) recurringTitles.add(t);
    }

    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 65, 12, 69),
              Color.fromARGB(255, 54, 13, 57),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -30,
              child: _buildBlob(160, _accentColor.withValues(alpha: 0.12)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── A) Header ──────────────────────────────────────────────
                  buildFeedBadge(
                    'April',
                    color: Colors.black,
                    radius: 14,
                    fontSize: 12,
                    textColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  ),

                  const SizedBox(height: 10),

                  Transform.rotate(
                    angle: -0.02,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.pop,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'BIG MOMENTS',
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFF1E1E1E),
                              fontSize: 34,
                              height: 1.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── B) Big Moment Blocks ───────────────────────────────────
                  Expanded(
                    child: bigMoments.isEmpty
                        ? Center(
                            child: Text(
                              'Keine Highlights diesen Monat.',
                              style: GoogleFonts.dmSans(
                                color: Colors.white38,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: bigMoments.map((entry) {
                              final title = resolvePreferredShowTitle(entry,
                                  fallback: 'Unbekannt');
                              final meta = _momentMeta(entry);
                              final date =
                                  _shortDate(entry['datetime']?.toString());
                              return _MomentBlock(
                                emoji: meta.emoji,
                                label: meta.label,
                                title: title,
                                date: date,
                              );
                            }).toList(),
                          ),
                  ),

                  // ── C) Footer: Recurring Shows ─────────────────────────────
                  if (recurringTitles.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('📺', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.dmSans(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                                children: [
                                  const TextSpan(
                                      text: 'Außerdem diesen Monat: '),
                                  TextSpan(
                                    text: recurringTitles.take(4).join(' & '),
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (recurringTitles.length > 4)
                                    TextSpan(
                                        text:
                                            ' + ${recurringTitles.length - 4} weitere'),
                                  const TextSpan(text: ' laufen wöchentlich.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
    );
  }
}

// ─── Moment Block ─────────────────────────────────────────────────────────────

class _MomentBlock extends StatelessWidget {
  final String emoji;
  final String label;
  final String title;
  final String date;

  static const _accentColor = AppColors.pop;

  const _MomentBlock({
    required this.emoji,
    required this.label,
    required this.title,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 253, 235, 254),
        //borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: _accentColor.withValues(alpha: 0.22), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Emoji icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color.fromARGB(255, 252, 214, 255),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),

          const SizedBox(width: 12),

          // Title + label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: Color.fromARGB(255, 54, 13, 57),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    color: _accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),

          // Date chip
          if (date.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                date,
                style: GoogleFonts.montserrat(
                  color: _accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
