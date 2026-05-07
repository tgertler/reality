import 'package:flutter/material.dart';
import 'package:frontend/features/favorites_management/presentation/widgets/favorite_heart_button.dart';
import 'package:frontend/features/feed_management/data/models/feed_item.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/feed_card_helpers.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/feed_tiktok_tag_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class NextBigPremiereFeedCard extends StatelessWidget {
  final FeedItem item;

  const NextBigPremiereFeedCard({super.key, required this.item});

  static const heroPink = Color.fromARGB(255, 248, 144, 255);

  // Returns e.g. "3 Tage", "Heute!", "Gestern"
  String _countdown(String? raw) {
    if (raw == null || raw.isEmpty) return '?';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '?';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'HEUTE!';
    if (diff == 1) return 'MORGEN';
    if (diff < 0) return 'LÄUFT';
    return 'NOCH $diff TAGE';
  }

  String _shortDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '';
    const months = [
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
    return '${dt.day}. ${months[dt.month]}';
  }

  @override
  Widget build(BuildContext context) {
    final title =
        resolvePreferredShowTitle(item.data, fallback: 'Unbekannte Show');
    final showId = item.data['show_id']?.toString() ?? '';
    final rawDate = item.data['datetime']?.toString();
    final countdownText = _countdown(rawDate);
    final dateLabel = _shortDate(rawDate);
    final isUrgent = countdownText == 'HEUTE!' || countdownText == 'MORGEN';

    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.zero,
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFFFFE6FF), // helles Pink
              Color(0xFFF3D4FF), // Soft Lavender
              Color(0xFFEBC1FF), // Orchid
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative shapes — same language as next_3_premieres
            Positioned(
              top: -40,
              left: -30,
              child: Transform.rotate(
                angle: -0.35,
                child: _buildDiamond(130, heroPink.withValues(alpha: 0.25)),
              ),
            ),
            Positioned(
              top: 120,
              right: -40,
              child: _buildCircle(100, heroPink.withValues(alpha: 0.18)),
            ),
            Positioned(
              bottom: -30,
              left: 40,
              child: _buildCircle(70, heroPink.withValues(alpha: 0.12)),
            ),

            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  Text('NÄCHSTE GROßE PREMIERE',
                      style: GoogleFonts.montserrat(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      )),

                  const SizedBox(height: 28),

                  // ── HERO: Countdown ──────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
                    // decoration: BoxDecoration(
                    //   color: isUrgent
                    //       ? const Color.fromARGB(255, 243, 87, 254)
                    //       : Colors.black.withValues(alpha: 0.85),
                    //   border: isUrgent
                    //       ? Border.all(
                    //           color: const Color.fromARGB(255, 94, 42, 98),
                    //           width: 1.5,
                    //         )
                    //       : null,
                    //   boxShadow: isUrgent
                    //       ? [
                    //           BoxShadow(
                    //             color: heroPink.withValues(alpha: 0.35),
                    //             blurRadius: 24,
                    //             offset: const Offset(0, 10),
                    //           ),
                    //         ]
                    //       : null,
                    // ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            countdownText,
                            style: GoogleFonts.montserrat(
                              color: Colors.black,
                              fontSize: 65,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                              letterSpacing: -1.5,
                            ),
                          ),
                        ),
                        // Ghost rank number like next_3_premieres
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Show title block (rank-card style, #2) ───────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.black,
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              if (dateLabel.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded,
                                        size: 13, color: Colors.white60),
                                    const SizedBox(width: 6),
                                    Text(
                                      dateLabel,
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white60,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          '!',
                          style: GoogleFonts.montserrat(
                            color: Colors.white
                                .withValues(alpha: isUrgent ? 0.4 : 0.15),
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Favorite CTA
                  if (showId.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    FeedCardTikTokTag(
                      showId: showId,
                      prefix: 'Trending auf TikTok: ',
                      isDark: false,
                    ),
                  ],
                  if (showId.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        children: [
                          FavoriteHeartButton(
                            showId: showId,
                            showTitle: title,
                            size: 26,
                            inactiveColor: Colors.black38,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Merken',
                            style: GoogleFonts.montserrat(
                              color: Colors.black54,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiamond(double size, Color color) {
    return Transform.rotate(
      angle: 0.785,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
