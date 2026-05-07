import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/features/favorites_management/presentation/widgets/favorite_heart_button.dart';
import 'package:frontend/features/feed_management/data/models/feed_item.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/feed_card_helpers.dart';
import 'package:google_fonts/google_fonts.dart';

// Background color matching the screenshot: very dark purple
class SeasonFinaleFeedCard extends StatelessWidget {
  final FeedItem item;

  const SeasonFinaleFeedCard({super.key, required this.item});

  /// Returns "29.04" style date label.
  String _shortDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '';
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final title = resolvePreferredShowTitle(item.data, fallback: 'Season Finale');
    final showId = item.data['show_id']?.toString() ?? '';
    final dateLabel = _shortDate(item.data['datetime']?.toString());

    return Padding(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Headline ─────────────────────────────────────────────
              Text(
                'FINALE',
                style: GoogleFonts.montserrat(
                  color: AppColors.pop,
                  fontSize: 52,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ooh Ooh',
                style: GoogleFonts.dmSans(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),

              // ── Hype Curve ────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _HypeCurvePainter(accentColor: AppColors.pop),
                      child: Container(),
                    ),
                  ),
                ),
              ),

              // ── Show title block ──────────────────────────────────────
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F1F1),
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.black, width: 2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(4, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    if (dateLabel.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        dateLabel,
                        style: GoogleFonts.dmSans(
                          color: Colors.black54,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── CTA text ──────────────────────────────────────────────
              Text(
                'Favorisiere die Show, um nicht das Finale zu verpassen!',
                style: GoogleFonts.dmSans(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 14),

              // ── Favorite button ───────────────────────────────────────
              if (showId.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    FavoriteHeartButton(
                      showId: showId,
                      showTitle: title,
                      size: 40,
                      inactiveColor: Colors.black38,
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Season Hype Curve Painter ────────────────────────────────────────────────

class _HypeCurvePainter extends CustomPainter {
  final Color accentColor;

  const _HypeCurvePainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Normalised y-values for the hype arc (0 = bottom, 1 = top)
    // Slow start → mid build → drama dip → finale peak
    final points = [
      Offset(0, h * 0.85),
      Offset(w * 0.12, h * 0.80),
      Offset(w * 0.22, h * 0.70),
      Offset(w * 0.30, h * 0.62),
      Offset(w * 0.40, h * 0.55),
      Offset(w * 0.48, h * 0.48),
      Offset(w * 0.55, h * 0.52), // drama dip
      Offset(w * 0.62, h * 0.40),
      Offset(w * 0.70, h * 0.30),
      Offset(w * 0.78, h * 0.20),
      Offset(w * 0.86, h * 0.10),
      Offset(w * 0.92, h * 0.04), // near peak
      Offset(w, h * 0.02), // finale peak
    ];

    // Glow fill under the curve
    // final fillPath = Path();
    // fillPath.moveTo(0, h);
    // fillPath.lineTo(points.first.dx, points.first.dy);
    // for (int i = 1; i < points.length; i++) {
    //   final prev = points[i - 1];
    //   final curr = points[i];
    //   final cpX = (prev.dx + curr.dx) / 2;
    //   fillPath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    // }
    // fillPath.lineTo(w, h);
    // fillPath.close();

    // final fillPaint = Paint()
    //   ..shader = LinearGradient(
    //     begin: Alignment.topCenter,
    //     end: Alignment.bottomCenter,
    //     colors: [
    //       accentColor.withValues(alpha: 0.22),
    //       accentColor.withValues(alpha: 0.0),
    //     ],
    //   ).createShader(Rect.fromLTWH(0, 0, w, h));
    // canvas.drawPath(fillPath, fillPaint);

    // Main curve line — grey up to last segment, then red
    final splitIndex = points.length - 3;

    // Grey portion
    final greyLine = Paint()
      ..color = const Color(0xFF333333)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final greyPath = Path();
    greyPath.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i <= splitIndex; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cpX = (prev.dx + curr.dx) / 2;
      greyPath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(greyPath, greyLine);

    // Accent (red) portion — finale run-up
    final redLine = Paint()
      ..color = accentColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final redPath = Path();
    redPath.moveTo(points[splitIndex].dx, points[splitIndex].dy);
    for (int i = splitIndex + 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cpX = (prev.dx + curr.dx) / 2;
      redPath.cubicTo(cpX, prev.dy, cpX, curr.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(redPath, redLine);

    // Peak dot
    final peak = points.last;
    canvas.drawCircle(
      peak,
      10,
      Paint()..color = accentColor,
    );
    canvas.drawCircle(
      peak,
      20,
      Paint()
        ..color = accentColor.withValues(alpha: 0.30)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_HypeCurvePainter old) => old.accentColor != accentColor;
}
