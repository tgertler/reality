import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/features/feed_management/data/models/feed_item.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/feed_card_helpers.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ThrowbackFeedCard extends StatelessWidget {
  final FeedItem item;

  const ThrowbackFeedCard({super.key, required this.item});

  int? _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final label = (item.data['label']?.toString().trim().isNotEmpty == true)
        ? item.data['label'].toString().trim()
        : 'Throwback der Woche';

    final momentText =
        (item.data['moment_text']?.toString().trim().isNotEmpty == true)
            ? item.data['moment_text'].toString().trim()
            : 'Der legendäre Moment, über den immer noch alle reden.';

    final showTitle =
      resolvePreferredShowTitle(item.data, fallback: 'Unbekannte Show');

    final showId = item.data['show_id']?.toString();
    final seasonNumber = _asInt(item.data['season_number']);
    final episodeNumber = _asInt(item.data['episode_number']);
    final ctaLabel = (item.data['cta_label']?.toString().trim().isNotEmpty == true)
        ? item.data['cta_label'].toString().trim()
        : 'Szene anschauen';
    final sticker =
        (item.data['sticker_label']?.toString().trim().isNotEmpty == true)
            ? item.data['sticker_label'].toString().trim()
            : 'OG Moment';

    final contextParts = <String>[showTitle];
    if (seasonNumber != null) {
      contextParts.add('Staffel $seasonNumber');
    }
    if (episodeNumber != null) {
      contextParts.add('Episode $episodeNumber');
    }

    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.zero,
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFFF6E9D9),
              Color(0xFFF2C8D2),
              Color(0xFFE8B7A4),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -24,
              left: -28,
              child: Transform.rotate(
                angle: -0.24,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E).withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -30,
              bottom: -36,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E1E1E).withValues(alpha: 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      buildFeedBadge(
                        label,
                        color: Colors.black,
                        radius: 14,
                        fontSize: 12,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                        textColor: Colors.white,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF2A8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF3A2A1C),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          sticker,
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF3A2A1C),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'LEGENDÄRER MOMENT',
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFF1E1E1E),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    momentText,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFF1E1E1E),
                      fontSize: 30,
                      height: 1.04,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF1E1E1E).withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      contextParts.join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF1E1E1E),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (showId != null && showId.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextButton.icon(
                        onPressed: () =>
                            context.push('${AppRoutes.showOverview}/$showId'),
                        icon: const Icon(
                          Icons.replay,
                          size: 18,
                          color: AppColors.pop,
                        ),
                        label: Text(
                          ctaLabel,
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
}
