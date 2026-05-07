import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/utils/streaming_service_logo.dart';
import 'package:frontend/features/bingo_management/presentation/providers/bingo_session_provider.dart';
import 'package:frontend/features/calendar_management/domain/entities/calendar_event_with_show.dart';
import 'package:frontend/features/favorites_management/presentation/widgets/favorite_heart_button.dart';
import 'package:frontend/features/user_management/presentation/providers/user_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class NewReleasesWidget extends ConsumerWidget {
  final List<CalendarEventWithShow> events;
  final PageController pageController;

  const NewReleasesWidget({
    super.key,
    required this.events,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bingoState = ref.watch(bingoSessionProvider);
    final activeSession = bingoState.activeSession;
    return PageView.builder(
      padEnds: false,
      controller: pageController,
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];

        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Container(
            color: Colors.black,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.push('${AppRoutes.showOverview}/${event.show.showId}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.show.displayTitle.isEmpty
                              ? 'Unknown Title'
                              : event.show.displayTitle,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              DateFormat('dd.MM.yyyy').format(
                                  event.calendarEvent.startDatetime.toLocal()),
                              style: GoogleFonts.dmSans(
                                  color: Colors.white70, fontSize: 14),
                            ),
                            if (event.season.seasonNumber != null &&
                                event.season.seasonNumber! > 0) ...[                            
                              const SizedBox(width: 15),
                              Text(
                                'S${event.season.seasonNumber}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white38,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // Container(
                      //   padding: const EdgeInsets.symmetric(
                      //       horizontal: 6, vertical: 2),
                      //   decoration: BoxDecoration(
                      //     color: AppColors.pop,
                      //     borderRadius: BorderRadius.circular(4),
                      //   ),
                      //   child: Text(
                      //     'NEU',
                      //     style: GoogleFonts.montserrat(
                      //       color: Colors.black,
                      //       fontSize: 9,
                      //       fontWeight: FontWeight.w700,
                      //       letterSpacing: 0.8,
                      //     ),
                      //   ),
                      // ),
                      () {
                        final showEventId =
                            event.calendarEvent.showEventId;
                        final hasBingoTarget = showEventId != null &&
                            showEventId.trim().isNotEmpty;
                        final hasActiveForThisEvent =
                            activeSession != null &&
                                activeSession.showEventId == showEventId;
                        if (!hasBingoTarget) return const SizedBox.shrink();
                        return GestureDetector(
                          onTap: bingoState.isBusy
                              ? null
                              : () async {
                                  if (activeSession != null) {
                                    ref
                                        .read(bingoSessionProvider.notifier)
                                        .openActiveSessionOverlay();
                                    return;
                                  }
                                  final userId =
                                      ref.read(userNotifierProvider).user?.id;
                                  if (userId == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                            'Melde dich an, um Bingo zu spielen.'),
                                        duration: const Duration(seconds: 3),
                                        action: SnackBarAction(
                                          label: 'Einloggen',
                                          onPressed: () =>
                                              context.push(AppRoutes.login),
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  await ref
                                      .read(bingoSessionProvider.notifier)
                                      .startSessionForShowEvent(
                                        showEventId,
                                        userId: userId,
                                        openOverlay: true,
                                      );
                                },
                          child: Transform.rotate(
                            angle: -0.05,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                border: Border.fromBorderSide(
                                  BorderSide(color: Colors.black, width: 2),
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(6)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.live_tv_rounded,
                                size: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        );
                      }(),
                      const Spacer(),
                      FavoriteHeartButton(
                        showId: event.show.showId,
                        showTitle: event.show.displayTitle,
                        size: 26,
                        inactiveColor: Colors.white24,
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        height: 18,
                        width: 46,
                        child: SvgPicture.asset(
                          getStreamingServiceLogo(
                              event.season.streamingOption ?? 'default'),
                          allowDrawingOutsideViewBox: true,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
