import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/features/feed_management/data/models/feed_item.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _kGenericBg = Color(0xFF292244);

class GenericFeedCard extends StatelessWidget {
  final FeedItem item;

  const GenericFeedCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final subtitle = item.data['subtitle']?.toString().trim().isNotEmpty == true
        ? item.data['subtitle'].toString().trim()
        : item.data['message']?.toString().trim().isNotEmpty == true
            ? item.data['message'].toString().trim()
            :
            'Dein täglicher Hub fuer Reality-TV: Kalender, Trends und die besten Momente in einer App.';

    final bullets = <String>[
      'Personalisierter Feed fuer deine Shows',
      'Smartes Tracking fuer Premieren und Finale',
      'Buzz, Recaps und Community-Momente',
    ];

    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.78,
        color: _kGenericBg,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'UNSCRIPTED',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 48,
                    height: 0.95,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2.0,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 26),
                  child: Text(
                    'APP',
                    style: GoogleFonts.montserrat(
                      color: AppColors.pop,
                      fontSize: 48,
                      height: 0.95,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(color: AppColors.pop.withValues(alpha: 0.34)),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.pop.withValues(alpha: 0.16),
                          border: Border.all(color: AppColors.pop.withValues(alpha: 0.44)),
                        ),
                        child: Text(
                          'DEIN REALITYSHOW-BEGLEITER',
                          style: GoogleFonts.dmSans(
                            color: AppColors.pop,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        subtitle,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 18,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (final text in bullets) ...[
                        _FeatureRow(text: text),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.feed),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      color: Colors.white,
                      child: Text(
                        'Feed entdecken',
                        style: GoogleFonts.dmSans(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.calendar),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        'Kalender',
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;

  const _FeatureRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: AppColors.pop,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.dmSans(
              color: Colors.white70,
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
