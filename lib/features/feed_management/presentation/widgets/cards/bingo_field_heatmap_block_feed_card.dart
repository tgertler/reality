import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/features/feed_management/data/models/feed_item.dart';
import 'package:google_fonts/google_fonts.dart';

class BingoFieldHeatmapBlockFeedCard extends StatelessWidget {
  final FeedItem item;

  const BingoFieldHeatmapBlockFeedCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final data = item.data;
    final totalSessions = _parseInt(data['total_sessions']);
    final topFields = _parseRows(data['top_fields']);
    final coldFields = _parseRows(data['cold_fields']);

    return Container(
      height: MediaQuery.of(context).size.height * 0.84,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WAS DIE CROWD',
              style: GoogleFonts.montserrat(
                color: Colors.black,
                fontSize: 36,
                height: 0.95,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.4,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 0),
              child: Text(
                'ABHAKT',
                style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontSize: 36,
                  height: 0.95,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.4,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Text(
            //   'Heatmap aller Sessions · seit dem Start',
            //   style: GoogleFonts.dmSans(
            //     color: Colors.black45,
            //     fontSize: 11,
            //     fontWeight: FontWeight.w600,
            //   ),
            // ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.black, width: 2),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DATENBASIS',
                    style: GoogleFonts.dmSans(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    '$totalSessions Sessions',
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (totalSessions <= 0 || topFields.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'Noch zu wenig Daten fur eine Heatmap.',
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
                    Text(
                      'TOP 5 FELDER',
                      style: GoogleFonts.dmSans(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < topFields.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _HeatRow(
                          rank: i + 1,
                          label: topFields[i]['label'] as String,
                          checkedRate: _parseDouble(topFields[i]['checked_rate']),
                        ),
                      ),
                    if (coldFields.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(width: 3, height: 14, color: AppColors.secondary),
                          const SizedBox(width: 8),
                          Text(
                            'SELTEN ABGEHAKT',
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final row in coldFields)
                            _ColdFieldChip(
                              label: row['label'] as String,
                              checkedRate: _parseDouble(row['checked_rate']),
                            ),
                        ],
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

  static List<Map<String, dynamic>> _parseRows(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
}

class _HeatRow extends StatelessWidget {
  final int rank;
  final String label;
  final double checkedRate;

  const _HeatRow({
    required this.rank,
    required this.label,
    required this.checkedRate,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = checkedRate.clamp(0, 100).toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
          Row(
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
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${clamped.toStringAsFixed(1)}%',
                style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth * (clamped / 100);
              return Stack(
                children: [
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      border: Border.all(color: Colors.black12),
                    ),
                  ),
                  Container(
                    width: barWidth,
                    height: 5,
                    color: AppColors.secondary,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ColdFieldChip extends StatelessWidget {
  final String label;
  final double checkedRate;

  const _ColdFieldChip({required this.label, required this.checkedRate});

  @override
  Widget build(BuildContext context) {
    final clamped = checkedRate.clamp(0, 100).toDouble();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
        ],
      ),
      child: Text(
        '$label (${clamped.toStringAsFixed(1)}%)',
        style: GoogleFonts.dmSans(
          color: Colors.black,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
