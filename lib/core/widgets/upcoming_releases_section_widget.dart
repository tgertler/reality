import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/next_release_widget.dart';
import 'package:frontend/features/calendar_management/domain/entities/calendar_event_with_show.dart';
import 'package:google_fonts/google_fonts.dart';

class UpcomingPremieresSectionWidget extends StatelessWidget {
  final List<CalendarEventWithShow> events;
  final PageController controller;
  final bool showHeader;

  const UpcomingPremieresSectionWidget({
    super.key,
    required this.events,
    required this.controller,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
              child: Text(
                '🔜 BALD',
                style: GoogleFonts.montserrat(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Nächste Premiere',
              style: GoogleFonts.montserrat(
                color: const Color(0xFF1E1E1E),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ],
        events.isEmpty
            ? Text(
                'Keine kommenden Premieren',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              )
            : SizedBox(
                height: 165,
                child: NextReleaseWidget(
                  events: events,
                ),
              ),
      ],
    );
  }
}