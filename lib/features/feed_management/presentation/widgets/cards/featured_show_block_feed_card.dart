import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/features/favorites_management/presentation/widgets/favorite_heart_button.dart';
import 'package:frontend/features/feed_management/data/models/feed_item.dart';
import 'feed_card_helpers.dart';
import 'package:google_fonts/google_fonts.dart';

class FeaturedShowBlockFeedCard extends StatelessWidget {
  final FeedItem item;

  const FeaturedShowBlockFeedCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final title = resolvePreferredShowTitle(item.data, fallback: 'Featured Show');
    final showId = item.data['show_id']?.toString() ?? '';
    final hookLine = item.data['hook_line']?.toString() ??
        'Eine Show, die du einfach sehen musst.';

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
              Text(
                'UNSERE',
                style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontSize: 34,
                  height: 0.95,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.6,
                ),
              ),
              Text(
                'EMPFEHLUNG',
                style: GoogleFonts.montserrat(
                  color: AppColors.pop,
                  fontSize: 34,
                  height: 0.95,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.6,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 132,
                height: 8,
                color: AppColors.pop,
              ),
              const SizedBox(height: 30),
              Text(
                title.toUpperCase(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontSize: 38,
                  height: 0.95,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
                      '❝',
                      style: const TextStyle(
                        color: AppColors.pop,
                        fontSize: 26,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hookLine,
                      style: GoogleFonts.dmSans(
                        color: Colors.black87,
                        fontSize: 18,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 11,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.pop,
                      border: Border.fromBorderSide(
                        BorderSide(color: Colors.black, width: 2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(3, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      'Mehr zur Show',
                      style: GoogleFonts.montserrat(
                        color: Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (showId.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    FavoriteHeartButton(
                      showId: showId,
                      showTitle: title,
                      size: 28,
                      inactiveColor: Colors.black38,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
