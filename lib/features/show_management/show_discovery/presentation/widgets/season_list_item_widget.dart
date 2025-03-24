import 'package:flutter/material.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/season.dart';

class SeasonListItemWidget extends StatelessWidget {
  final Season season;

  const SeasonListItemWidget({super.key, required this.season});

  @override
  Widget build(BuildContext context) {
    final year = DateFormat('yyyy').format(season.streamingReleaseDate);
    return GestureDetector(
      onTap: () {
        context.push('${AppRoutes.seasonOverview}/${season.id}');
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: season.seasonNumber % 2 == 0
              ? const Color.fromARGB(255, 30, 30, 30)
              : const Color.fromARGB(255, 37, 37,
                  37), // Unterschiedliche Farben für jede zweite Zeile
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[800]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Text(
                'Staffel ${season.seasonNumber}',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 7.0, right: 7.0),
              child: Container(
                child: Icon(
                  Icons.fiber_manual_record,
                  size: 5,
                  color: const Color.fromARGB(255, 213, 245, 245),
                ),
              ),
            ),
            Text(
              year,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 7.0, right: 7.0),
              child: Container(
                child: Icon(
                  Icons.fiber_manual_record,
                  size: 5,
                  color: const Color.fromARGB(255, 213, 245, 245),
                ),
              ),
            ),
            Expanded(
              child: Text(
                '${season.totalEpisodes} Episode(n)',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: SizedBox(
                width: 20,
                child: Icon(Icons.chevron_right),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
