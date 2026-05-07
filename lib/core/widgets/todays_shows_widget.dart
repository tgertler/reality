import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/core/utils/streaming_service_logo.dart';
import 'package:frontend/features/bingo_management/presentation/providers/bingo_session_provider.dart';
import 'package:frontend/features/calendar_management/domain/entities/calendar_event_with_show.dart';
import 'package:frontend/features/calendar_management/presentation/utils/calendar_event_grouping.dart';
import 'package:frontend/features/favorites_management/presentation/widgets/favorite_heart_button.dart';
import 'package:frontend/features/user_management/presentation/providers/user_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class TodayShowsWidget extends ConsumerWidget {
  final List<CalendarEventWithShow> events;

  const TodayShowsWidget({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bingoState = ref.watch(bingoSessionProvider);
    final activeSession = bingoState.activeSession;
    final groupedEvents = groupConsecutiveByKey<CalendarEventWithShow>(
      events,
      (event) => event.show.showId,
    );

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groupedEvents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 3),
      itemBuilder: (context, index) {
        final groupedEvent = groupedEvents[index];
        final event = groupedEvent.item;
        final isContinuation = groupedEvent.isContinuation;

        return GestureDetector(
          onTap: () =>
              context.push('${AppRoutes.showOverview}/${event.show.showId}'),
          child: Container(
            margin: EdgeInsets.only(left: isContinuation ? 18 : 0),
            padding: EdgeInsets.symmetric(
              horizontal: isContinuation ? 10 : 12,
              vertical: isContinuation ? 7 : 12,
            ),
            decoration: BoxDecoration(
              color: isContinuation ? const Color(0xFF111111) : Colors.black,
              border: Border(
                left: BorderSide(
                  color: isContinuation ? Colors.white24 : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                // SizedBox(
                //   width: 26,
                //   child: Text(
                //     isContinuation
                //         ? '↳'
                //         : (index + 1).toString().padLeft(2, '0'),
                //     style: GoogleFonts.montserrat(
                //       color: Colors.white60,
                //       fontSize: isContinuation ? 11 : 12,
                //       fontWeight: FontWeight.w500,
                //     ),
                //   ),
                // ),
                // const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.show.displayTitle.isEmpty
                              ? 'Unknown Title'
                              : event.show.displayTitle,
                          style: GoogleFonts.dmSans(
                            fontSize: isContinuation ? 12.5 : 18,
                            fontWeight: isContinuation
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color:
                                isContinuation ? Colors.white70 : Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (event.season.seasonNumber != null &&
                          event.season.seasonNumber! > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          'S${event.season.seasonNumber}',
                          style: GoogleFonts.montserrat(
                            fontSize: isContinuation ? 10 : 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                      if (event.calendarEvent.episodeNumber != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          'E${event.calendarEvent.episodeNumber}',
                          style: GoogleFonts.montserrat(
                            fontSize: isContinuation ? 10 : 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: isContinuation ? 38 : 44,
                  height: 20,
                  child: SvgPicture.asset(
                    getStreamingServiceLogo(
                      event.season.streamingOption ?? 'default',
                    ),
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 5),
                if (!isContinuation) ...[
                  () {
                    final showEventId = event.calendarEvent.showEventId;
                    final hasBingoTarget =
                        showEventId != null && showEventId.trim().isNotEmpty;
                    final hasActiveForThisEvent = activeSession != null &&
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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            hasActiveForThisEvent
                                ? Icons.live_tv_rounded
                                : Icons.play_arrow_rounded,
                            size: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    );
                  }(),
                  const SizedBox(width: 6),
                  FavoriteHeartButton(
                    showId: event.show.showId,
                    showTitle: event.show.displayTitle,
                    size: 25,
                    inactiveColor: Colors.white24,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
