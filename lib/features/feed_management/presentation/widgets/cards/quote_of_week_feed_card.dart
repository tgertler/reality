import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/features/feed_management/data/models/feed_item.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/feed_card_helpers.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class QuoteOfWeekFeedCard extends StatelessWidget {
  final FeedItem item;

  const QuoteOfWeekFeedCard({super.key, required this.item});

  int? _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  double _quoteFontSize(String text) {
    final length = text.trim().length;
    if (length <= 58) return 36;
    if (length <= 100) return 31;
    if (length <= 150) return 27;
    return 24;
  }

  String _seasonEpisodeLine(int? seasonNumber, int? episodeNumber) {
    if (seasonNumber == null && episodeNumber == null) return '';
    final parts = <String>[];
    if (seasonNumber != null) parts.add('S$seasonNumber');
    if (episodeNumber != null) parts.add('E$episodeNumber');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final quote =
        (item.data['quote']?.toString().trim().isNotEmpty == true)
            ? item.data['quote'].toString().trim()
            : 'Ich hab kein Drama gesucht - das Drama hat mich gefunden.';

    final speaker =
        (item.data['speaker_name']?.toString().trim().isNotEmpty == true)
            ? item.data['speaker_name'].toString().trim()
            : 'Unbekannt';

    final showTitle =
        resolvePreferredShowTitle(item.data, fallback: 'Unbekannte Show');

    final showId = item.data['show_id']?.toString();
    final seasonNumber = _asInt(item.data['season_number']);
    final episodeNumber = _asInt(item.data['episode_number']);
    final ctaLabel =
        (item.data['cta_label']?.toString().trim().isNotEmpty == true)
            ? item.data['cta_label'].toString().trim()
            : 'Zur Show';

    final seasonEpisode = _seasonEpisodeLine(seasonNumber, episodeNumber);
    final quoteFontSize = _quoteFontSize(quote);

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
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.pop, width: 5),
                  ),
                ),
                padding: const EdgeInsets.only(left: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QUOTE DER',
                      style: GoogleFonts.montserrat(
                        color: Colors.black,
                        fontSize: 44,
                        height: 0.95,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                      ),
                    ),
                    Text(
                      'WOCHE',
                      style: GoogleFonts.montserrat(
                        color: AppColors.pop,
                        fontSize: 44,
                        height: 0.95,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
                        '"',
                        style: GoogleFonts.montserrat(
                          color: AppColors.pop,
                          fontSize: 48,
                          height: 0.7,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Transform.rotate(
                        angle: -0.01,
                        child: Text(
                          quote,
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            color: Colors.black,
                            fontSize: quoteFontSize,
                            height: 1.02,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                        decoration: BoxDecoration(
                          color: AppColors.pop.withValues(alpha: 0.14),
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: Text(
                          '- $speaker',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            color: Colors.black,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _metaPill('Show', showTitle),
                          if (seasonEpisode.isNotEmpty)
                            _metaPill('Folge', seasonEpisode),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (showId != null && showId.isNotEmpty)
                GestureDetector(
                  onTap: () => context.push('${AppRoutes.showOverview}/$showId'),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.black,
                          size: 17,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ctaLabel,
                          style: GoogleFonts.dmSans(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        border: Border.all(color: Colors.black26),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: GoogleFonts.dmSans(
                color: Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: GoogleFonts.dmSans(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
