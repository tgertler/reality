import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/utils/streaming_service_logo.dart';
import 'package:frontend/features/calendar_management/domain/entities/calendar_event_with_show.dart';
import 'package:frontend/features/favorites_management/presentation/widgets/favorite_heart_button.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class NextReleaseWidget extends StatelessWidget {
  final List<CalendarEventWithShow> events;

  const NextReleaseWidget({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedEvents = [...events]
      ..sort((a, b) => a.calendarEvent.startDatetime
          .compareTo(b.calendarEvent.startDatetime));

    final nextEvent = sortedEvents.first;
    final dateStr = DateFormat('dd.MM.yyyy')
        .format(nextEvent.calendarEvent.startDatetime.toLocal());
    final streamOpt = (nextEvent.season.streamingOption ?? '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.push('${AppRoutes.showOverview}/${nextEvent.show.showId}'),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 5,
                    height: 118,
                    color: AppColors.pop,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nextEvent.show.displayTitle.isEmpty
                              ? 'Unbekannter Titel'
                              : nextEvent.show.displayTitle,
                          style: GoogleFonts.montserrat(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Premiere: $dateStr',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                            if (nextEvent.season.seasonNumber != null &&
                                nextEvent.season.seasonNumber! > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                '·',
                                style: GoogleFonts.dmSans(
                                    color: Colors.white24, fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'S${nextEvent.season.seasonNumber}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ],
                        ),
                        // if (streamOpt.isNotEmpty) ...[
                        //   const SizedBox(height: 6),
                        //   Text(
                        //     streamOpt,
                        //     maxLines: 1,
                        //     overflow: TextOverflow.ellipsis,
                        //     style: GoogleFonts.dmSans(
                        //       fontSize: 12,
                        //       color: Colors.white54,
                        //       fontWeight: FontWeight.w600,
                        //     ),
                        //   ),
                        // ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          FavoriteHeartButton(
            showId: nextEvent.show.showId,
            showTitle: nextEvent.show.displayTitle,
            size: 22,
            inactiveColor: Colors.white30,
          ),
          const SizedBox(width: 8),
          if (streamOpt.isNotEmpty)
            SizedBox(
              height: 24,
              width: 44,
              child: SvgPicture.asset(
                getStreamingServiceLogo(streamOpt),
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }
}