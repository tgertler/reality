import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GenreWidget extends StatelessWidget {
  final String genre;
  final Color accentColor;

  const GenreWidget({
    super.key,
    required this.genre,
    this.accentColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = genre.trim();
    if (trimmed.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Row(
        children: [
          Text(
            'Genre:',
            style: GoogleFonts.dmSans(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor,
              border: Border.all(color: accentColor.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              trimmed,
              style: GoogleFonts.montserrat(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}