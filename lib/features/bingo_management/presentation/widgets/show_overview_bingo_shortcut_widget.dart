import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/features/calendar_management/domain/entities/calendar_event_with_show.dart';
import 'package:frontend/features/premium_management/domain/entities/premium_required_exception.dart';
import 'package:frontend/features/premium_management/presentation/pages/paywall_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/calendar_management/presentation/providers/show_events_provider.dart';
import 'package:frontend/features/bingo_management/presentation/providers/bingo_session_provider.dart';
import 'package:frontend/features/user_management/presentation/providers/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class ShowOverviewBingoShortcutWidget extends ConsumerWidget {
  final String showId;

  const ShowOverviewBingoShortcutWidget({
    super.key,
    required this.showId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bingoSessionProvider);
    final showEventsState = ref.watch(showEventsProvider);
    final activeSession = state.activeSession;
    final hasActiveOnOtherShow =
        activeSession != null && activeSession.showId != showId;
    final activeShowLabel = activeSession?.showTitle.trim().isNotEmpty == true
        ? activeSession!.showTitle
        : 'anderer Show';

    final now = DateTime.now();
    final nextEvent = showEventsState.nextEvent;
    final lastEvent = showEventsState.lastEvent;
    final isNextEventToday = nextEvent != null &&
      _isSameDay(nextEvent.calendarEvent.startDatetime.toLocal(), now);
    final bingoTargetEvent = isNextEventToday ? nextEvent : lastEvent;
    final targetShowEventId = bingoTargetEvent?.calendarEvent.showEventId;
    final hasBingoTarget =
      targetShowEventId != null && targetShowEventId.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(
            left: BorderSide(
              color: AppColors.secondary.withValues(alpha: 0.7),
              width: 2.5,
            ),
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.live_tv_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.link_rounded,
                        size: 14,
                        color: AppColors.secondary.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isNextEventToday
                            ? 'VERKNÜPFT MIT HEUTIGEM EVENT'
                            : 'VERKNÜPFT MIT LETZTEM EVENT',
                        style: GoogleFonts.montserrat(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bingo Area',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (hasBingoTarget)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.09),
                        ),
                      ),
                      child: Text(
                        _targetLabel(bingoTargetEvent!),
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    Text(
                      'Kein passendes Show-Event für Bingo verfügbar.',
                      style: GoogleFonts.dmSans(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  if (activeSession != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Aktive Session ist bereit.',
                      style: GoogleFonts.dmSans(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (hasActiveOnOtherShow) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        border: Border(
                          left: BorderSide(
                            color: AppColors.secondary.withValues(alpha: 0.7),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        'Aktive Bingo läuft auf: $activeShowLabel',
                        style: GoogleFonts.dmSans(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: state.isBusy ||
                            (activeSession == null && !hasBingoTarget)
                        ? null
                        : () async {
                            if (activeSession != null) {
                              ref
                                  .read(bingoSessionProvider.notifier)
                                  .openActiveSessionOverlay();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Aktive Bingo-Session geöffnet'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                              return;
                            }

                            final userId =
                                ref.read(userNotifierProvider).user?.id;
                            if (userId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                      'Melde dich an, um Bingo zu spielen.'),
                                  duration: const Duration(seconds: 4),
                                  action: SnackBarAction(
                                    label: 'Einloggen',
                                    onPressed: () {
                                      context.push(AppRoutes.login);
                                    },
                                  ),
                                ),
                              );
                              return;
                            }
                            try {
                              await ref
                                  .read(bingoSessionProvider.notifier)
                                  .startSessionForShowEvent(
                                    targetShowEventId!,
                                    userId: userId,
                                    openOverlay: true,
                                  );
                            } on PremiumRequiredException catch (e) {
                              if (context.mounted) {
                                await PaywallScreen.open(
                                  context,
                                  sourceFeature: e.feature,
                                  sourceMessage: e.message,
                                );
                              }
                              return;
                            }

                            final started =
                                ref.read(bingoSessionProvider).activeSession !=
                                    null;
                            if (started && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bingo-Session gestartet'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                    child: Text(
                      activeSession == null
                          ? (isNextEventToday
                              ? 'Watchparty (Bingo) für heutiges Event starten'
                              : 'Watchparty (Bingo) für letztes Event starten')
                          : 'Session öffnen',
                    ),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage!,
                      style: GoogleFonts.dmSans(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _targetLabel(CalendarEventWithShow event) {
    final dt = event.calendarEvent.startDatetime.toLocal();
    final date = '${_two(dt.day)}.${_two(dt.month)}.${dt.year}';
    final episode = event.calendarEvent.episodeNumber != null
        ? 'E${event.calendarEvent.episodeNumber}'
        : 'Episode';
    return isSameDay(dt, DateTime.now())
        ? '$episode • heute ($date)'
        : '$episode • letztes Event ($date)';
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
