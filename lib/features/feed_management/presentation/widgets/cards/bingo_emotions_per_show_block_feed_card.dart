import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/features/feed_management/data/models/feed_item.dart';
import 'package:google_fonts/google_fonts.dart';

class BingoEmotionsPerShowBlockFeedCard extends StatelessWidget {
  final FeedItem item;

  const BingoEmotionsPerShowBlockFeedCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final data = item.data;
    final shows = _parseShows(data['shows']);
    final totalSessions = shows.fold<int>(
      0,
      (sum, s) => sum + _parseInt(s['session_count']),
    );
    final totalReactions = shows.fold<int>(0, (sum, s) {
      final emotions = _parseShows(s['top_emotions']);
      return sum + emotions.fold<int>(0, (acc, e) => acc + _parseInt(e['count']));
    });

    return Container(
      height: MediaQuery.of(context).size.height * 0.84,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CROWD MOOD',
                        style: GoogleFonts.montserrat(
                          color: Colors.black,
                          fontSize: 34,
                          height: 0.95,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Emotionen aus Watchparty-Sessions · pro Show',
              style: GoogleFonts.dmSans(
                color: Colors.black45,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MoodStat(
                    label: 'WATCHPARTYS',
                    value: totalSessions.toString(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MoodStat(
                    label: 'REAKTIONEN',
                    value: totalReactions.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (shows.isEmpty)
              _emptyState()
            else
              Expanded(
                child: Column(
                  children: shows.asMap().entries.map((entry) {
                    final idx = entry.key;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: idx < shows.length - 1 ? 8 : 0),
                        child: _ShowEmotionRow(
                          show: entry.value,
                          rank: idx + 1,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Expanded(
      child: Center(
        child: Text(
          'Noch keine Reaktionen',
          style: GoogleFonts.dmSans(color: Colors.black45, fontSize: 14),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _parseShows(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

class _ShowEmotionRow extends StatelessWidget {
  final Map<String, dynamic> show;
  final int rank;

  const _ShowEmotionRow({required this.show, required this.rank});

  String get showTitle => show['show_title'] as String? ?? '';
  int get sessionCount {
    final v = show['session_count'];
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  List<Map<String, dynamic>> get topEmotions {
    final raw = show['top_emotions'];
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  @override
  Widget build(BuildContext context) {
    final first = topEmotions.isNotEmpty ? topEmotions[0] : <String, dynamic>{};
    final second = topEmotions.length > 1 ? topEmotions[1] : <String, dynamic>{};
    final third = topEmotions.length > 2 ? topEmotions[2] : <String, dynamic>{};

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          //border: Border.all(color: Colors.black, width: 2),
          // boxShadow: const [
          //   BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
          // ],
        ),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#$rank',
                style: GoogleFonts.montserrat(
                  color: AppColors.secondary,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  showTitle.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$sessionCount Watchpartys',
                style: GoogleFonts.dmSans(
                  color: Colors.black45,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _EmotionPill(emotion: first)),
              const SizedBox(width: 6),
              Expanded(child: _EmotionPill(emotion: second)),
              const SizedBox(width: 6),
              Expanded(child: _EmotionPill(emotion: third)),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

class _MoodStat extends StatelessWidget {
  final String label;
  final String value;

  const _MoodStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.black45,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmotionPill extends StatelessWidget {
  final Map<String, dynamic> emotion;

  const _EmotionPill({required this.emotion});

  String get emoji => emotion['emoji'] as String? ?? '';
  String get dimension => emotion['dimension'] as String? ?? '';
  int get count {
    final v = emotion['count'];
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (emotion.isEmpty) {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black12,
          border: Border.all(color: Colors.black12),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 25)),
              const SizedBox(width: 10),
              Text(
                count.toString(),
                style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          // if (dimension.isNotEmpty) ...[
          //   const SizedBox(height: 3),
          //   Text(
          //     dimension,
          //     maxLines: 1,
          //     overflow: TextOverflow.ellipsis,
          //     style: GoogleFonts.dmSans(
          //       color: Colors.black45,
          //       fontSize: 9,
          //       fontWeight: FontWeight.w700,
          //     ),
          //   ),
          // ],
        ],
      ),
    );
  }
}
