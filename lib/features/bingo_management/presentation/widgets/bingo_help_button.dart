import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BingoHelpButton extends StatelessWidget {
  final String title;
  final String description;
  final String usage;
  final Color accentColor;
  final List<String> steps;
  final List<String> rules;

  const BingoHelpButton({
    super.key,
    required this.title,
    required this.description,
    required this.usage,
    required this.accentColor,
    this.steps = const [],
    this.rules = const [],
  });

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _buildBulletList(List<String> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 8),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry,
                      style: GoogleFonts.dmSans(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Text(
              title,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Was ist das?'),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: GoogleFonts.dmSans(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  if (steps.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildSectionTitle('So spielst du'),
                    const SizedBox(height: 8),
                    _buildBulletList(steps),
                  ],
                  const SizedBox(height: 6),
                  _buildSectionTitle('Kurz gesagt'),
                  const SizedBox(height: 8),
                  Text(
                    usage,
                    style: GoogleFonts.dmSans(
                      color: Colors.white60,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  if (rules.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildSectionTitle('Regeln'),
                    const SizedBox(height: 8),
                    _buildBulletList(rules),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Schließen',
                  style: GoogleFonts.dmSans(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white24,
          ),
          color: Colors.white.withValues(alpha: 0.04),
        ),
        alignment: Alignment.center,
        child: Text(
          '?',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
