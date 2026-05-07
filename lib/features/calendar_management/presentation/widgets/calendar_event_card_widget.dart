import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/core/utils/streaming_service_logo.dart';
import 'package:frontend/features/favorites_management/presentation/widgets/favorite_heart_button.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarEventCardWidget extends StatelessWidget {
  final String calendarEventId;
  final DateTime startDatetime;
  final DateTime endDatetime;
  final String showName;
  final String showId;
  final String? showEventId;
  final String streamingService;
  final int dramaLevel;
  final int? seasonNumber;

  const CalendarEventCardWidget({
    super.key,
    required this.calendarEventId,
    required this.startDatetime,
    required this.endDatetime,
    required this.showName,
    required this.showId,
    this.showEventId,
    required this.streamingService,
    required this.dramaLevel,
    this.seasonNumber,
  });

  Color _dramaColor(int level) {
    if (level >= 10) return const Color.fromARGB(211, 255, 255, 255);
    if (level >= 9) return const Color.fromARGB(213, 255, 255, 255);
    if (level >= 8) return const Color.fromARGB(153, 255, 255, 255);
    return const Color.fromARGB(83, 255, 255, 255);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        showEventId != null && showEventId!.isNotEmpty
            ? '${AppRoutes.showEventDetail}/$showEventId'
            : '${AppRoutes.showOverview}/$showId',
      ),
      child: Container(
        width: double.infinity,
        height: 80,
        padding: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          border: Border.all(
              color: const Color.fromARGB(255, 255, 248, 255), width: 1.5),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),

            // Titel + Drama Bar darunter
            Expanded(
              flex: 24,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titel
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          showName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (seasonNumber != null && seasonNumber! > 0) ...[  
                        const SizedBox(width: 10),
                        Text(
                          'S$seasonNumber',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Drama Level kompakt
                  Row(
                    children: [
                      // Balken
                      Container(
                        height: 6,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Stack(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: (dramaLevel / 10) * 60,
                              decoration: BoxDecoration(
                                color: _dramaColor(dramaLevel),
                                //borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 6),

                      // // Level-Zahl
                      // Text(
                      //   dramaLevel.toString(),
                      //   style: TextStyle(
                      //     fontSize: 11,
                      //     fontWeight: FontWeight.bold,
                      //     color: _dramaColor(dramaLevel),
                      //   ),
                      // ),

                      const SizedBox(width: 8),

                      // Label rechts daneben
                      Text(
                        "Drama-Level",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Spacer(),

            // Streaming Service Logo + Favorite
            SizedBox(
              height: 24,
              width: 64,
              child: SvgPicture.asset(
                getStreamingServiceLogo(streamingService),
                height: 26,
                width: 36,
                fit: BoxFit.contain,
              ),
            ),
            const Spacer(),
            FavoriteHeartButton(
              showId: showId,
              showTitle: showName,
              size: 20,
              inactiveColor: Colors.white30,
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
