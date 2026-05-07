import 'package:flutter/material.dart';
import 'package:frontend/features/feed_management/data/models/feed_item.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/feed_card_helpers.dart';
import 'package:google_fonts/google_fonts.dart';

class Next3PremieresBlockFeedCard extends StatelessWidget {
  final FeedItem item;

  const Next3PremieresBlockFeedCard({super.key, required this.item});

  static const Color heroPink =
      Color.fromARGB(255, 248, 144, 255); // Leitfarbe

  @override
  Widget build(BuildContext context) {
    final items = parseFeedItems(item.data['items']);
    if (items.isEmpty) return const SizedBox.shrink();

    final hero = items.first;
    final upcoming = items.skip(1).take(2).toList();

    final heroTitle = resolvePreferredShowTitle(hero, fallback: 'Unknown');
    final heroDate = formatFeedDate(hero['datetime']?.toString());

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
              Color.fromARGB(255, 229, 173, 255), // Orchid

            ],
          ),
        ),
        child: Stack(
          children: [
            // 🎨 SUBTLE SHAPES (ruhiger, Ton-in-Ton)
            Positioned(
              top: -40,
              left: -30,
              child: Transform.rotate(
                angle: -0.35,
                child: _buildDiamond(
                  130,
                  heroPink.withValues(alpha: 0.25),
                ),
              ),
            ),
            Positioned(
              top: 120,
              right: -40,
              child: _buildCircle(
                100,
                heroPink.withValues(alpha: 0.18),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BADGE
                  buildFeedBadge(
                    'Die nächsten 3 Premieren',
                    color: Colors.black,
                    radius: 14,
                    fontSize: 12,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    textColor: Colors.white,
                  ),

                  const SizedBox(height: 26),

                  // 🥇 PLATZ 1 — Hero
                  _RankCard(
                    rank: 1,
                    title: heroTitle,
                    subtitle: heroDate,
                    entry: hero,
                    context: context,
                  ),

                  const SizedBox(height: 12),

                  // 🥈🥉 PLATZ 2 + 3
                  ...upcoming.asMap().entries.map((e) {
                    final rank = e.key + 2;
                    final entry = e.value;
                    final title =
                        resolvePreferredShowTitle(entry, fallback: 'Unknown');
                    final date = formatFeedDate(entry['datetime']?.toString());
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RankCard(
                        rank: rank,
                        title: title,
                        subtitle: date,
                        entry: entry,
                        context: context,
                      ),
                    );
                  }),

                  const SizedBox(height: 20),
                    const SizedBox(height: 28),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "NEXT UP!",
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF1E1E1E),
                            fontSize: 80,
                            height: 1.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.1,
                          ),
                        ),
                      ],
                    ),
                    

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Helpers ----------

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

// ─── Ranking Card ──────────────────────────────────────────────────────────────

class _RankCard extends StatelessWidget {
  final int rank;
  final String title;
  final String subtitle;
  final Map<String, dynamic> entry;
  final BuildContext context;

  const _RankCard({
    required this.rank,
    required this.title,
    required this.subtitle,
    required this.entry,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final isHero = rank == 1;

    return Container(
      padding: EdgeInsets.all(isHero ? 18 : 14),
      decoration: BoxDecoration(
        color: isHero
            ? const Color.fromARGB(255, 243, 87, 254)
            : const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.85),
        boxShadow: isHero
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
        border: isHero
            ? Border.all(
                color: const Color.fromARGB(255, 94, 42, 98),
                width: 1.5,
              )
            : null,
      ),
      child: Row(
        children: [
          // ── Rank Badge ──────────────────────────────


          const SizedBox(width: 16),

          // ── Title + Subtitle ─────────────────────────
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
                    fontSize: isHero ? 18 : 15,
                    fontWeight:
                        isHero ? FontWeight.w800 : FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    color: Colors.white60,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // ── Rank Number (large background accent) ────
          Text(
            '#$rank',
            style: GoogleFonts.montserrat(
              color: Colors.white.withValues(alpha: isHero ? 0.4 : 0.2),
              fontSize: isHero ? 72 : 56,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}