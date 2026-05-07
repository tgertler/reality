import 'package:flutter/material.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/features/calendar_management/domain/entities/resolved_calendar_event.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class CalendarCreatorEventCard extends StatelessWidget {
  final ResolvedCalendarEvent event;

  const CalendarCreatorEventCard({super.key, required this.event});

  static const _blue = Color(0xFF4DB6FF);

  String _kindLabel(String? kind) {
    switch (kind) {
      case 'reaction_video':
        return 'REACTION';
      case 'review':
        return 'REVIEW';
      case 'compilation':
        return 'COMPILATION';
      case 'interview':
        return 'INTERVIEW';
      default:
        return kind?.toUpperCase() ?? 'CREATOR';
    }
  }

  Future<void> _openYoutube() async {
    final url = event.creatorEventYoutubeUrl ?? event.creatorYoutubeChannelUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(event.startDatetime.toLocal());
    final title =
        event.creatorEventTitle ?? event.creatorName ?? 'Creator Event';
    final hasYoutube = event.creatorEventYoutubeUrl != null ||
        event.creatorYoutubeChannelUrl != null;

    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.creatorEventDetail,
        extra: event,
      ),
      child: Container(
        width: double.infinity,
        height: 80,
        padding: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          border: Border.all(
              color: const Color.fromARGB(255, 255, 255, 255), width: 1.5),
        ),
        child: Row(
          children: [
            Container(width: 4, color: _blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        color: _blue,
                        child: Text(
                          _kindLabel(event.creatorEventKind),
                          style: GoogleFonts.montserrat(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      if (event.creatorName != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            event.creatorName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white60,
                  ),
                ),
                if (hasYoutube) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _openYoutube,
                    child: const Icon(
                      Icons.play_circle_outline,
                      color: _blue,
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
