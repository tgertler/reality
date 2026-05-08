import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/features/feed_management/data/models/feed_item.dart';
import 'package:google_fonts/google_fonts.dart';

class BingoFeaturePromoFeedCard extends StatelessWidget {
  final FeedItem item;

  const BingoFeaturePromoFeedCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final headline =
        item.data['headline']?.toString().trim().isNotEmpty == true
            ? item.data['headline'].toString().trim()
            : 'TRASH-BINGO';
    final subline = item.data['subline']?.toString().trim().isNotEmpty == true
        ? item.data['subline'].toString().trim()
        : 'Hab mehr Spaß bei deiner Watchparty. Jetzt auf jeder Folge.';

    return Padding(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(
                  color: AppColors.pop,
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.black, width: 2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                child: Text(
                  'WATCHPARTY',
                  style: GoogleFonts.dmSans(
                    color: Colors.black,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const _PosterBingoGrid(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
                child: Text(
                  headline.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    color: AppColors.pop,
                    fontSize: 34,
                    height: 0.96,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 0, 0),
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.dmSans(
                      color: Colors.black,
                      fontSize: 22,
                      height: 1.18,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      const TextSpan(text: 'Probier unsere'),
                      TextSpan(
                        text: ' Watchparty',
                        style: GoogleFonts.dmSans(
                          color: Colors.black,
                          fontSize: 22,
                          height: 1.18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const TextSpan(
                        text: ' aus - jetzt auf jeder Folge verfügbar.',
                      ),
                    ],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (subline !=
                  'Hab mehr Spaß bei deiner Watchparty. Jetzt auf jeder Folge.') ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.06),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    subline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PosterBingoGrid extends StatelessWidget {
  const _PosterBingoGrid();

  static const List<Color> _cellColors = [
    Color(0xFFCDCDCD),
    Color(0xFFBFBFBF),
    Color(0xFFD7D7D7),
    Color(0xFFB7B7B7),
    Color(0xFFC9C9C9),
    Color(0xFFAFAFAF),
    Color(0xFFD4D4D4),
    Color(0xFFBBBBBB),
    Color(0xFFC5C5C5),
    Color(0xFFB3B3B3),
    Color(0xFFD1D1D1),
    Color(0xFFA9A9A9),
    Color(0xFFCFCFCF),
    Color(0xFFB5B5B5),
    Color(0xFFC2C2C2),
    Color(0xFFAEAEAE),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
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
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 16,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final hasCross = index == 5 || index == 10 || index == 11;
            return Container(
              decoration: BoxDecoration(
                color: hasCross ? AppColors.pop : _cellColors[index],
                border: Border.all(color: Colors.black, width: 1.2),
              ),
              child: hasCross
                  ? const Center(
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.black,
                        size: 54,
                        weight: 900,
                      ),
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }
}
