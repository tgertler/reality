import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/features/feed_management/data/models/feed_item.dart';
import 'package:google_fonts/google_fonts.dart';

class TrendingShowsBlockFeedCard extends StatelessWidget {
  final FeedItem item;

  const TrendingShowsBlockFeedCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final data = item.data;
    final shows = _parseShows(data['shows']);
    final totalInteractions = _parseInt(data['total_interactions']);
    final maxCount = shows.isEmpty
        ? 1
        : shows
            .map((s) => _parseInt(s['interaction_count']))
            .reduce((a, b) => a > b ? a : b);
    final topTitle = shows.isNotEmpty ? (shows.first['title'] as String? ?? '') : '';

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IM TREND',
                        style: GoogleFonts.montserrat(
                          color: Colors.black,
                          fontSize: 36,
                          height: 0.95,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.4,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 14),
                        child: Text(
                          'FAVORITEN',
                          style: GoogleFonts.montserrat(
                            color: AppColors.pop,
                            fontSize: 32,
                            height: 0.95,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.rotate(
                  angle: 0.1, // Adjust the rotation angle as needed
                  child: Padding(
                    padding: const EdgeInsets.only(right: 40.0),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.pop,
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Meistgemerkte Shows · letzte 7 Tage',
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
                  child: _StatBox(
                    label: 'FAVORITEN',
                    value: totalInteractions.toString(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatBox(
                    label: 'AUF #1',
                    value: topTitle.isEmpty ? '-' : topTitle,
                    compact: true,
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
                        child: _ShowRow(
                          show: entry.value,
                          maxCount: maxCount,
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
          'Noch keine Daten',
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

class _ShowRow extends StatelessWidget {
  final Map<String, dynamic> show;
  final int maxCount;

  const _ShowRow({
    required this.show,
    required this.maxCount,
  });

  int get count => _parseInt(show['interaction_count']);
  int get rank => _parseInt(show['rank']);
  String get title => (show['title'] as String? ?? '').toUpperCase();

  int _parseInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final barFraction = maxCount > 0 ? count / maxCount : 0.0;
    final pct = (barFraction * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '#$rank',
                  style: GoogleFonts.montserrat(
                    color: AppColors.pop,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.montserrat(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                count.toString(),
                style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 8,
                  width: constraints.maxWidth,
                  color: Colors.black12,
                ),
                Container(
                  height: 8,
                  width: constraints.maxWidth * barFraction,
                  color: Colors.black,
                ),
              ],
            );
          }),
          const SizedBox(height: 4),
          Text(
            '$pct% vom Top-Wert',
            style: GoogleFonts.montserrat(
              color: Colors.black45,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final bool compact;

  const _StatBox({
    required this.label,
    required this.value,
    this.compact = false,
  });

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
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              color: Colors.black,
              fontSize: compact ? 14 : 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}
