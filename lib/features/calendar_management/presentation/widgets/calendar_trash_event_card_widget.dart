import 'package:flutter/material.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/features/calendar_management/domain/entities/resolved_calendar_event.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class CalendarTrashEventCard extends StatelessWidget {
  final ResolvedCalendarEvent event;

  const CalendarTrashEventCard({super.key, required this.event});

  static const _gold = Color(0xFFFFD700);

  Future<void> _openExternal() async {
    final url = event.trashEventExternalUrl;
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(event.startDatetime.toLocal());
    final title = event.trashEventTitle ?? 'Community Event';

    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.trashEventDetail,
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
            Container(width: 4, color: _gold),
            const SizedBox(width: 10),
            const Text('🎉', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // if (event.trashEventPrice != null) ...[
                      //   Container(
                      //     padding: const EdgeInsets.symmetric(
                      //         horizontal: 5, vertical: 2),
                      //     color: _gold,
                      //     child: Text(
                      //       event.trashEventPrice!,
                      //       style: GoogleFonts.montserrat(
                      //         fontSize: 9,
                      //         fontWeight: FontWeight.w800,
                      //         color: Colors.black,
                      //       ),
                      //     ),
                      //   ),
                      //   const SizedBox(width: 6),
                      // ],
                      if (event.trashEventLocation != null)
                        Flexible(
                          child: Text(
                            event.trashEventLocation!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: Colors.white54,
                            ),
                          ),
                        ),
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
                if (event.trashEventExternalUrl != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _openExternal,
                    child: const Icon(
                      Icons.open_in_new,
                      color: _gold,
                      size: 18,
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
