import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/season.dart';

class SeasonListItemWidget extends StatelessWidget {
  final Season season;
  final Color accentColor;

  const SeasonListItemWidget({
    super.key,
    required this.season,
    this.accentColor = AppColors.pop,
  });

  @override
  Widget build(BuildContext context) {
    final year = DateFormat('yyyy').format(season.streamingReleaseDate);
    final streamOpt = season.streamingOption.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '${season.seasonNumber}',
              style: GoogleFonts.montserrat(
                color: accentColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Staffel ${season.seasonNumber} · $year · ${season.totalEpisodes} Episoden${streamOpt.isNotEmpty ? ' · $streamOpt' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
