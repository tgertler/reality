import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/core/utils/streaming_service_logo.dart';
import 'package:frontend/features/bingo_management/presentation/providers/bingo_session_provider.dart';
import 'package:frontend/features/calendar_management/domain/entities/resolved_calendar_event.dart';
import 'package:frontend/features/favorites_management/presentation/widgets/favorite_heart_button.dart';
import 'package:frontend/features/user_management/presentation/providers/user_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarResolvedShowEventCard extends ConsumerWidget {
  final ResolvedCalendarEvent event;

  const CalendarResolvedShowEventCard({super.key, required this.event});

  String _subtypeLabel(String? subtype) {
    switch (subtype) {
      case 'premiere':
        return 'PREMIERE';
      case 'finale':
        return 'FINALE';
      case 'reunion':
        return 'REUNION';
      case 'episode':
        return 'EPISODE';
      default:
        return subtype?.toUpperCase() ?? '';
    }
  }

  Color _subtypeBadgeColor(String? subtype) {
    switch (subtype) {
      case 'premiere':
        return AppColors.pop;
      case 'finale':
        return const Color(0xFFFF6B6B);
      case 'reunion':
        return const Color(0xFFFFD166);
      default:
        return const Color.fromARGB(255, 113, 113, 113);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bingoState = ref.watch(bingoSessionProvider);
    final showTitle = (event.showEventShowShortTitle?.trim().isNotEmpty == true)
        ? event.showEventShowShortTitle!
        : (event.showEventShowTitle ?? '');
    final showId = event.showEventShowId ?? '';
    final subtype = event.showEventSubtype;
    final episode = event.showEventEpisodeNumber;
    final seasonNumber = event.showEventSeasonNumber;
    final badgeLabel = _subtypeLabel(subtype);
    final streamingService = event.showEventStreamingOption ?? '';

    final showEventId = event.showEventId;
    final activeSession = bingoState.activeSession;
    final hasActiveForThisEvent =
        activeSession != null && activeSession.showEventId == showEventId;
    final hasBingoTarget =
        showEventId != null && showEventId.trim().isNotEmpty;

    return GestureDetector(
      onTap: showId.isNotEmpty
          ? () => context.push('${AppRoutes.showOverview}/$showId')
          : null,
      child: Container(
        width: double.infinity,
        height: 80,
        padding: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color.fromARGB(255, 255, 248, 255),
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left accent bar coloured by subtype
            Container(
              width: 4,
              color: _subtypeBadgeColor(subtype),
            ),
            const SizedBox(width: 12),

            // Title + subtype badge
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    showTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (badgeLabel.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          color: _subtypeBadgeColor(subtype),
                          child: Text(
                            badgeLabel,
                            style: GoogleFonts.montserrat(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: subtype == 'episode'
                                  ? Colors.white70
                                  : Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (seasonNumber != null && seasonNumber > 0) ...[
                        Text(
                          'S$seasonNumber',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white38,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (episode != null)
                        Text(
                          'E$episode',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white38,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Streaming logo
            if (streamingService.isNotEmpty)
              SizedBox(
                height: 24,
                width: 56,
                child: SvgPicture.asset(
                  getStreamingServiceLogo(streamingService),
                  height: 24,
                  width: 56,
                  fit: BoxFit.contain,
                ),
              ),
            const SizedBox(width: 8),

            // Bingo-Button — Bold Sticker Look
            if (hasBingoTarget)
              GestureDetector(
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
              ),
            if (hasBingoTarget) const SizedBox(width: 6),
            if (showId.isNotEmpty)
              FavoriteHeartButton(
                showId: showId,
                showTitle: showTitle,
                size: 28,
                inactiveColor: Colors.white30,
              ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
