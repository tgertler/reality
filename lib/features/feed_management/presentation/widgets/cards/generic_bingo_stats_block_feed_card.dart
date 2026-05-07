import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/features/feed_management/data/models/feed_item.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/feed_card_helpers.dart';
import 'package:google_fonts/google_fonts.dart';

class GenericBingoStatsBlockFeedCard extends StatelessWidget {
  final FeedItem item;

  const GenericBingoStatsBlockFeedCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final rawItems = item.data['items'] ?? item.data;
    final statsItems = parseFeedItems(rawItems).take(5).toList();

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
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(
                  color: AppColors.pop,
                ),
                child: Text(
                  'BINGO STATS',
                  style: GoogleFonts.dmSans(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'BINGO',
                style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontSize: 44,
                  height: 0.95,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Text(
                  'STATS HEUTE',
                  style: GoogleFonts.montserrat(
                    color: AppColors.pop,
                    fontSize: 44,
                    height: 0.95,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: statsItems.isEmpty
                    ? Center(
                        child: Text(
                          'Heute wurden noch keine Bingo-Statistiken erfasst.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: Colors.black45,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (var i = 0; i < statsItems.length; i++) ...[
                            _StatsRow(index: i + 1, data: statsItems[i]),
                            if (i != statsItems.length - 1)
                              const Divider(
                                height: 10,
                                color: Colors.black12,
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

class _StatsRow extends StatelessWidget {
  final int index;
  final Map<String, dynamic> data;

  const _StatsRow({required this.index, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = _resolveTitle(data);
    final participants = _parseInt(data['participants']);
    final achieved = _parseInt(data['achieved_participants']);
    final avgScore = _parseDouble(data['avg_score']);
    final bestTimeSeconds = _parseInt(data['best_time_seconds']);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            color: AppColors.pop,
            child: Text(
              '$index',
              style: GoogleFonts.montserrat(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _StatPill(label: 'Teilnehmende', value: '$participants'),
                    _StatPill(label: 'Bingo', value: '$achieved'),
                    _StatPill(label: 'Avg Score', value: _formatScore(avgScore)),
                    _StatPill(label: 'Best Time', value: _formatTime(bestTimeSeconds)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _resolveTitle(Map<String, dynamic> map) {
    final candidate = resolvePreferredShowTitle(map, fallback: '');
    if (candidate.isNotEmpty) return candidate;

    final eventId = map['show_event_id']?.toString().trim() ?? '';
    if (eventId.isEmpty) return 'Unbekanntes Event';

    final suffix = eventId.length > 8 ? eventId.substring(0, 8) : eventId;
    return 'Show Event $suffix';
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatScore(double score) {
    if (score <= 0) return '-';
    return score.toStringAsFixed(1);
  }

  String _formatTime(int seconds) {
    if (seconds <= 0) return '-';
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins <= 0) return '${secs}s';
    return '${mins}m ${secs.toString().padLeft(2, '0')}s';
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;

  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        border: Border.all(color: Colors.black26),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.dmSans(
          color: Colors.black87,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
