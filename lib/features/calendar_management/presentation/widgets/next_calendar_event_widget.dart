import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/core/widgets/loading/app_skeleton.dart';
import 'package:frontend/features/bingo_management/presentation/providers/bingo_session_provider.dart';
import 'package:frontend/features/calendar_management/domain/entities/calendar_event_with_show.dart';
import 'package:frontend/features/calendar_management/presentation/providers/show_events_provider.dart';
import 'package:frontend/core/utils/streaming_service_logo.dart';
import 'package:frontend/features/user_management/presentation/providers/user_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class NextCalendarEventWidget extends ConsumerStatefulWidget {
  final String showId;
  final Color accentColor;

  const NextCalendarEventWidget({
    super.key,
    required this.showId,
    this.accentColor = AppColors.pop,
  });

  @override
  ConsumerState<NextCalendarEventWidget> createState() =>
      _NextCalendarEventWidgetState();
}

class _NextCalendarEventWidgetState
    extends ConsumerState<NextCalendarEventWidget> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(showEventsProvider.notifier).fetchNextEvent(widget.showId);
      ref.read(showEventsProvider.notifier).fetchUpcomingEvents(widget.showId);
    });
  }

  @override
  void didUpdateWidget(covariant NextCalendarEventWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showId != widget.showId) {
      ref.read(showEventsProvider.notifier).fetchNextEvent(widget.showId);
      ref.read(showEventsProvider.notifier).fetchUpcomingEvents(widget.showId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(showEventsProvider);
    final nextEvent = state.nextEvent;
    final lastEvent = state.lastEvent;
    final bingoState = ref.watch(bingoSessionProvider);
    final activeSession = bingoState.activeSession;
    final hasActiveOnOtherShow =
      activeSession != null && activeSession.showId != widget.showId;
    final activeShowLabel = activeSession?.showTitle.trim().isNotEmpty == true
      ? activeSession!.showTitle
      : 'anderer Show';

    if ((state.isLoadingNext || state.isLoadingUpcoming) &&
        nextEvent == null &&
        lastEvent == null) {
      return const _NextCalendarEventSkeleton();
    }

    if (nextEvent == null && lastEvent == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final isNextToday = nextEvent != null &&
        _isSameDay(nextEvent.calendarEvent.startDatetime.toLocal(), now);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Column(
        children: [
          if (nextEvent != null)
            _EventCard(
              title: 'Nächstes Event',
              event: nextEvent,
              accentColor: widget.accentColor,
              highlightToday: true,
              showBingoArea: isNextToday,
              isLinkedToBingo: isNextToday,
              hasActiveSession: activeSession != null,
              hasActiveOnOtherShow: hasActiveOnOtherShow,
              activeShowLabel: activeShowLabel,
              isBusy: bingoState.isBusy,
              onStartOrOpen: () async {
                if (activeSession != null) {
                  ref.read(bingoSessionProvider.notifier).openActiveSessionOverlay();
                  return;
                }

                final targetShowEventId = nextEvent.calendarEvent.showEventId;
                if (targetShowEventId == null || targetShowEventId.isEmpty) {
                  return;
                }

                final userId = ref.read(userNotifierProvider).user?.id;
                if (userId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      persist: false,
                      content: const Text('Melde dich an, um Bingo zu spielen.'),
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'Einloggen',
                        onPressed: () => context.push(AppRoutes.login),
                      ),
                    ),
                  );
                  return;
                }
                await ref.read(bingoSessionProvider.notifier).startSessionForShowEvent(
                      targetShowEventId,
                      userId: userId,
                      openOverlay: true,
                    );
              },
            ),
          if (!isNextToday && nextEvent != null && lastEvent != null)
            const SizedBox(height: 8),
          if (!isNextToday && lastEvent != null)
            _EventCard(
              title: 'Letztes Event',
              event: lastEvent,
              accentColor: widget.accentColor,
              highlightToday: false,
              showBingoArea: true,
              isLinkedToBingo: !isNextToday,
              hasActiveSession: activeSession != null,
              hasActiveOnOtherShow: hasActiveOnOtherShow,
              activeShowLabel: activeShowLabel,
              isBusy: bingoState.isBusy,
              onStartOrOpen: () async {
                if (activeSession != null) {
                  ref.read(bingoSessionProvider.notifier).openActiveSessionOverlay();
                  return;
                }

                final targetShowEventId = lastEvent.calendarEvent.showEventId;
                if (targetShowEventId == null || targetShowEventId.isEmpty) {
                  return;
                }

                final userId = ref.read(userNotifierProvider).user?.id;
                if (userId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      persist: false,
                      content: const Text('Melde dich an, um Bingo zu spielen.'),
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'Einloggen',
                        onPressed: () => context.push(AppRoutes.login),
                      ),
                    ),
                  );
                  return;
                }
                await ref.read(bingoSessionProvider.notifier).startSessionForShowEvent(
                      targetShowEventId,
                      userId: userId,
                      openOverlay: true,
                    );
              },
            ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _EventCard extends StatelessWidget {
  final String title;
  final CalendarEventWithShow event;
  final Color accentColor;
  final bool highlightToday;
  final bool showBingoArea;
  final bool isLinkedToBingo;
  final bool isBusy;
  final bool hasActiveSession;
  final bool hasActiveOnOtherShow;
  final String activeShowLabel;
  final VoidCallback onStartOrOpen;

  const _EventCard({
    required this.title,
    required this.event,
    required this.accentColor,
    this.highlightToday = false,
    this.showBingoArea = false,
    this.isLinkedToBingo = false,
    required this.isBusy,
    required this.hasActiveSession,
    required this.hasActiveOnOtherShow,
    required this.activeShowLabel,
    required this.onStartOrOpen,
  });

  @override
  Widget build(BuildContext context) {
    final ce = event.calendarEvent;
    final season = event.season;
    final dt = ce.startDatetime.toLocal();
    final dateStr = '${_two(dt.day)}.${_two(dt.month)}.${dt.year}';
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;

    final seasonInfo = (season.seasonNumber != null && season.seasonNumber! > 0)
        ? 'S${season.seasonNumber}'
        : null;
    final streamOpt = (season.streamingOption ?? '').trim();
    final showEventId = ce.showEventId;
    final showId = ce.showId;

    final iconBackgroundColor = highlightToday && isToday
        ? AppColors.pop
        : AppColors.pop;
    final iconColor = highlightToday && isToday ? Colors.black : Colors.black;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (showEventId != null && showEventId.isNotEmpty) {
            context.push('${AppRoutes.showEventDetail}/$showEventId');
            return;
          }
          if (showId.isNotEmpty) {
            context.push('${AppRoutes.showOverview}/$showId');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          color: Colors.black,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    color: iconBackgroundColor,
                    child: Icon(
                      title == 'Letztes Event' ? Icons.history : Icons.event_available,
                      color: iconColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Transform.rotate(
                              angle: -0.02,
                              child: Text(
                                title,
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white54,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            // if (isLinkedToBingo) ...[
                            //   const SizedBox(width: 8),
                            //   Container(
                            //     padding: const EdgeInsets.symmetric(
                            //       horizontal: 6,
                            //       vertical: 2,
                            //     ),
                            //     decoration: BoxDecoration(
                            //       color: accentColor.withValues(alpha: 0.12),
                            //       borderRadius: BorderRadius.circular(4),
                            //       border: Border.all(
                            //         color: accentColor.withValues(alpha: 0.55),
                            //       ),
                            //     ),
                            //     child: Text(
                            //       'BINGO',
                            //       style: GoogleFonts.montserrat(
                            //         fontSize: 9,
                            //         fontWeight: FontWeight.w800,
                            //         color: accentColor,
                            //         letterSpacing: 0.6,
                            //       ),
                            //     ),
                            //   ),
                            // ],
                            if (highlightToday && isToday) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.pop.withValues(alpha: 0.12),
                                  border: Border.all(
                                    color: AppColors.pop.withValues(alpha: 0.45),
                                  ),
                                  //borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'HEUTE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.pop,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                            
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              dateStr,
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            if (seasonInfo != null) ...[
                              const Text(
                                ' • ',
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                              Text(
                                seasonInfo,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (streamOpt.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 72,
                      height: 42,
                      padding: const EdgeInsets.all(6),
                      //color: Colors.white.withValues(alpha: 0.05),
                      child: Center(
                        child: SvgPicture.asset(
                          getStreamingServiceLogo(streamOpt),
                          allowDrawingOutsideViewBox: true,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white30,
                    size: 18,
                  ),
                ],
              ),
              if (showBingoArea) ...[
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: isBusy ||
                          (!hasActiveSession &&
                              (showEventId == null || showEventId.isEmpty))
                      ? null
                      : onStartOrOpen,
                  child: Transform.rotate(
                    angle: -0.020,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: AppColors.secondary,
                        border: Border.all(
                          color: Colors.black,
                          width: 2.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(4, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.live_tv_rounded,
                            color: Colors.black,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasActiveSession
                                      ? 'WATCHPARTY FORTSETZEN'
                                      : 'WATCHPARTY STARTEN',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  hasActiveSession
                                      ? 'Tippe hier zum Öffnen'
                                      : 'Bingo für dieses Event',
                                  style: GoogleFonts.dmSans(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.black,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (hasActiveOnOtherShow) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Aktive Session läuft auf: $activeShowLabel',
                    style: GoogleFonts.dmSans(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _two(int v) => v.toString().padLeft(2, '0');
}

class _NextCalendarEventSkeleton extends StatelessWidget {
  const _NextCalendarEventSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      child: const Row(
        children: [
          AppSkeletonBox(
              width: 42,
              height: 42,
              borderRadius: BorderRadius.all(Radius.circular(4))),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSkeletonBox(width: 90, height: 11),
                SizedBox(height: 8),
                AppSkeletonBox(width: 150, height: 18),
                SizedBox(height: 8),
                AppSkeletonBox(width: 84, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
