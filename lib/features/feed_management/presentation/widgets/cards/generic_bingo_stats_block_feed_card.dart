import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/features/feed_management/data/models/feed_item.dart';
import 'package:google_fonts/google_fonts.dart';

class GenericBingoStatsBlockFeedCard extends StatelessWidget {
  final FeedItem item;

  const GenericBingoStatsBlockFeedCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final d = item.data;
    final totalSessions = _parseInt(d['total_sessions']);
    final bingoRate = _parseDouble(d['bingo_rate']);
    final avgScore = _parseDouble(d['avg_score']);
    final avgTimeSecs = _parseInt(d['avg_time_to_bingo_seconds']);
    final avgFields = _parseDouble(d['avg_fields_at_bingo']);
    final topShows = _parseTopShows(d['top_shows']);
    final hasData = totalSessions > 0;

    return Padding(
      padding: EdgeInsets.zero,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.86,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WIE SPIELT',
                style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontSize: 38,
                  height: 0.95,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Text(
                  'DIE CROWD?',
                  style: GoogleFonts.montserrat(
                    color: AppColors.secondary,
                    fontSize: 38,
                    height: 0.95,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ø-Werte der letzten 7 Tage — alle Bingo-Läufe',
                style: GoogleFonts.dmSans(
                  color: Colors.black45,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              if (!hasData)
                Expanded(
                  child: Center(
                    child: Text(
                      'Die Community hat in den letzten 7 Tagen\nnoch kein Bingo gespielt.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        color: Colors.black45,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero: Bingo-Rate (full width)
                      _HeroStatBlock(
                        label: 'BINGO-RATE DER COMMUNITY',
                        value: '${bingoRate.toStringAsFixed(1)} %',
                      ),
                      const SizedBox(height: 10),
                      // Two-column: Sessions + Avg Score
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _StatBlock(
                                label: 'SESSIONS',
                                value: '$totalSessions',
                                sublabel: 'gesamt',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatBlock(
                                label: 'Ø SCORE',
                                value: avgScore > 0
                                    ? avgScore.toStringAsFixed(1)
                                    : '-',
                                sublabel: 'pro Lauf',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Two-column: Avg Zeit + Avg Felder
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _StatBlock(
                                label: 'Ø ZEIT',
                                value: _formatTime(avgTimeSecs),
                                sublabel: 'bis Bingo',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatBlock(
                                label: 'Ø FELDER',
                                value: avgFields > 0
                                    ? avgFields.toStringAsFixed(1)
                                    : '-',
                                sublabel: 'beim Bingo',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (topShows.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        // Top-3-Section header
                        Row(
                          children: [
                            Container(
                              width: 3,
                              height: 14,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'MEIST GESPIELT',
                              style: GoogleFonts.dmSans(
                                color: Colors.black,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (var i = 0; i < topShows.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: _TopShowRow(
                              rank: i + 1,
                              title: topShows[i]['show_title'] as String,
                              sessionCount: _parseInt(topShows[i]['session_count']),
                              isTop: i == 0,
                            ),
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

  static int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0.0;
  }

  static String _formatTime(int seconds) {
    if (seconds <= 0) return '-';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins <= 0) return '${secs}s';
    return '${mins}m ${secs.toString().padLeft(2, '0')}s';
  }

  static List<Map<String, dynamic>> _parseTopShows(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
}

/// Large teal hero block — Bingo-Rate.
class _HeroStatBlock extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStatBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    color: Colors.black,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2.0,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '🎯',
            style: const TextStyle(fontSize: 32),
          ),
        ],
      ),
    );
  }
}

/// Standard stat block — 2-column grid.
class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final String sublabel;

  const _StatBlock({
    required this.label,
    required this.value,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F1F1),
        border: Border.fromBorderSide(
          BorderSide(color: Colors.black, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.black54,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: Colors.black,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
              height: 1.0,
            ),
          ),
          Text(
            sublabel,
            style: GoogleFonts.dmSans(
              color: Colors.black38,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Single row in the Top-3 most-played shows list.
class _TopShowRow extends StatelessWidget {
  final int rank;
  final String title;
  final int sessionCount;
  final bool isTop;

  const _TopShowRow({
    required this.rank,
    required this.title,
    required this.sessionCount,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isTop ? Colors.black : const Color(0xFFF1F1F1),
        border: Border.fromBorderSide(
          BorderSide(color: Colors.black, width: isTop ? 2 : 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            offset: isTop ? const Offset(3, 3) : const Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            color: AppColors.secondary,
            child: Text(
              '$rank',
              style: GoogleFonts.montserrat(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                color: isTop ? Colors.white : Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sessionCount Sessions',
            style: GoogleFonts.dmSans(
              color: isTop ? AppColors.secondary : Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
