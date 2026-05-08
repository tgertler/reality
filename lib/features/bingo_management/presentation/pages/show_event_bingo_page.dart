import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/features/bingo_management/domain/entities/bingo_models.dart';
import 'package:frontend/features/premium_management/domain/entities/premium_required_exception.dart';
import 'package:frontend/features/premium_management/presentation/pages/paywall_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/bingo_management/presentation/providers/bingo_session_provider.dart';
import 'package:frontend/features/bingo_management/presentation/widgets/bingo_help_button.dart';
import 'package:frontend/features/bingo_management/presentation/widgets/bingo_overlay_widget.dart';
import 'package:frontend/features/user_management/presentation/providers/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class ShowEventBingoPage extends ConsumerWidget {
  final String showEventId;

  const ShowEventBingoPage({
    super.key,
    required this.showEventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(showEventBingoSummaryProvider(showEventId));
    final historyAsync = ref.watch(showEventBingoHistoryProvider(showEventId));
    final releasedAsync = ref.watch(showEventIsReleasedProvider(showEventId));
    final sessionState = ref.watch(bingoSessionProvider);
    final active = sessionState.activeSession;
    final hasActiveForThisEvent = active?.showEventId == showEventId;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF0F0F11),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.pop.withValues(alpha: 0.2),
                  const Color(0xFF2A1F2D),
                  const Color(0xFF141418),
                ],
              ),
            ),
            child: SafeArea(
              child: summaryAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Episode konnte nicht geladen werden: $error',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
                data: (summary) {
                  if (summary == null) {
                    return const Center(
                      child: Text(
                        'Keine Episode gefunden.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    children: [
                      Row(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.of(context).maybePop(),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EVENT ZUR SHOW',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                'Episode ${summary.episodeNumber}',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SummaryCard(summary: summary),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (_) {
                          final isReleased = releasedAsync.maybeWhen(
                            data: (v) => v,
                            orElse: () => false,
                          );
                          final canStartNewSession = isReleased;
                          return _ActionCard(
                            hasActiveForThisEvent: hasActiveForThisEvent,
                            hasAnyActiveSession: active != null,
                            activeSessionOtherEvent:
                                active != null && !hasActiveForThisEvent,
                            isBusy: sessionState.isBusy,
                            canStartNewSession: canStartNewSession,
                            onPressed: () async {
                              if (hasActiveForThisEvent) {
                                ref
                                    .read(bingoSessionProvider.notifier)
                                    .openActiveSessionOverlay();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Aktive Session geöffnet'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                                return;
                              }

                              if (active != null) {
                                ref
                                    .read(bingoSessionProvider.notifier)
                                    .openActiveSessionOverlay();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Aktive Session aus anderer Episode geöffnet'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              if (!canStartNewSession) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Bingo erst möglich, sobald die Episode erschienen ist.'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                                return;
                              }

                              final userId =
                                  ref.read(userNotifierProvider).user?.id;
                              if (userId == null) {
                                if (context.mounted) {
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
                                }
                                return;
                              }
                              try {
                                await ref
                                    .read(bingoSessionProvider.notifier)
                                    .startSessionForShowEvent(
                                      showEventId,
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
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Bingo-Session gestartet'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                      if (sessionState.errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          sessionState.errorMessage!,
                          style: GoogleFonts.dmSans(color: Colors.redAccent),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        'Bingo-Historie',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      historyAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (error, _) => Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Historie konnte nicht geladen werden: $error',
                            style: GoogleFonts.dmSans(color: Colors.redAccent),
                          ),
                        ),
                        data: (history) {
                          if (history.isEmpty) {
                            return Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.68),
                                border: Border(
                                  left: BorderSide(
                                    color:
                                        AppColors.pop.withValues(alpha: 0.75),
                                    width: 2.5,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.all(14),
                              child: Text(
                                'Noch keine abgeschlossenen Sessions.',
                                style:
                                    GoogleFonts.dmSans(color: Colors.white60),
                              ),
                            );
                          }

                          return Column(
                            children: history
                                .map(
                                  (entry) => _HistoryTile(
                                    entry: entry,
                                    onOpen: () async {
                                      await ref
                                          .read(bingoSessionProvider.notifier)
                                          .openHistoricalSessionOverlay(
                                              entry.sessionId);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Historische Session geöffnet (read-only)'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const BingoOverlayWidget(),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ShowEventBingoSummary summary;

  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final episodeLabel = summary.episodeNumber != null
        ? 'Episode ${summary.episodeNumber}'
        : 'Episode';
    final subtype = summary.eventSubtype?.toUpperCase() ?? 'SHOW EVENT';
    final start = summary.startDatetime;
    final timeLabel = start == null
        ? '-'
        : '${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')}.${start.year} ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        border: Border(
          left: BorderSide(
            color: AppColors.pop.withValues(alpha: 0.8),
            width: 2.5,
          ),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.displayTitle,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$subtype · $episodeLabel',
            style: GoogleFonts.montserrat(
              color: AppColors.pop,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            timeLabel,
            style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 13),
          ),
          if (summary.description != null &&
              summary.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              summary.description!.trim(),
              style: GoogleFonts.dmSans(
                color: Colors.white70,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final bool hasActiveForThisEvent;
  final bool hasAnyActiveSession;
  final bool activeSessionOtherEvent;
  final bool canStartNewSession;
  final bool isBusy;
  final VoidCallback onPressed;

  const _ActionCard({
    required this.hasActiveForThisEvent,
    required this.hasAnyActiveSession,
    required this.activeSessionOtherEvent,
    required this.canStartNewSession,
    required this.isBusy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = hasActiveForThisEvent
        ? 'Bingo öffnen'
        : hasAnyActiveSession
            ? 'Aktive Session öffnen'
            : 'Bingo starten';

    final helper = hasActiveForThisEvent
        ? 'Session ist aktiv und kann jederzeit fortgesetzt werden.'
        : hasAnyActiveSession
            ? 'Es gibt bereits eine aktive Session in einer anderen Episode.'
            : canStartNewSession
                ? 'Startet sofort eine neue Session für diese Episode.'
                : 'Bingo kann erst gestartet werden, wenn die Episode erschienen ist.';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        border: Border(
          left: BorderSide(
            color: AppColors.pop.withValues(alpha: 0.8),
            width: 2.5,
          ),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Episode-Bingo',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              BingoHelpButton(
                title: 'Wie funktioniert Bingo?',
                description:
                    'Bingo begleitet dich live durch die Episode. Du sammelst typische Momente und Zitate aus genau dieser Folge, bis eine Reihe, Spalte oder Diagonale voll ist.',
                usage:
                    'Session starten, live beim Schauen abhaken und die Runde nach der Episode wieder über die Historie nachvollziehen.',
                accentColor: AppColors.pop,
                steps: const [
                  'Starte die Session zu Beginn der Episode oder sobald du aktiv mitschauen willst.',
                  'Markiere Felder nur für Ereignisse, die in dieser Folge wirklich passieren.',
                  'Wenn eine Reihe, Spalte oder Diagonale voll ist, hast du Bingo erreicht.',
                ],
                rules: const [
                  'Nicht vorgreifen: Ein Feld wird erst gesetzt, wenn der Moment tatsächlich eingetreten ist.',
                  'Zitat-Felder zählen nur bei dem echten gesprochenen Satz oder einer sehr klaren Formulierung davon.',
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            helper,
            style: GoogleFonts.dmSans(color: Colors.white60),
          ),
          if (activeSessionOtherEvent) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              color: Colors.white.withValues(alpha: 0.08),
              child: Text(
                'Hinweis: Es läuft aktuell eine Session in einer anderen Episode.',
                style: GoogleFonts.dmSans(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            onPressed: (isBusy || (!hasAnyActiveSession && !canStartNewSession))
                ? null
                : onPressed,
            child: Text(label),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final BingoSessionHistoryEntry entry;
  final VoidCallback onOpen;

  const _HistoryTile({
    required this.entry,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final started =
        '${entry.startedAt.day.toString().padLeft(2, '0')}.${entry.startedAt.month.toString().padLeft(2, '0')}.${entry.startedAt.year} ${entry.startedAt.hour.toString().padLeft(2, '0')}:${entry.startedAt.minute.toString().padLeft(2, '0')}';

    final result = entry.bingoReached
        ? 'Bingo erreicht · ${entry.checkedCount}/${entry.totalCount}'
        : '${entry.checkedCount}/${entry.totalCount} Felder';

    final timeLabel = _formatDuration(entry.timeToBingoSeconds);
    final fieldsLabel = (entry.fieldsAtBingo ?? entry.checkedCount).toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        border: Border(
          left: BorderSide(
            color: AppColors.pop.withValues(alpha: 0.7),
            width: 2.2,
          ),
        ),
      ),
      child: ListTile(
        title: Text(
          started,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                result,
                style: GoogleFonts.dmSans(color: Colors.white60),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  ...List.generate(3, (index) {
                    final filled = index < entry.stars;
                    return Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Icon(
                        filled ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 14,
                        color: filled ? const Color(0xFFFFD700) : Colors.white30,
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    'Zeit: $timeLabel',
                    style: GoogleFonts.dmSans(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Felder: $fieldsLabel',
                    style: GoogleFonts.dmSans(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: onOpen,
      ),
    );
  }

  String _formatDuration(double? seconds) {
    if (seconds == null || seconds < 0 || seconds.isNaN || seconds.isInfinite) {
      return '--:--';
    }
    final rounded = seconds.round();
    final minutes = (rounded ~/ 60).toString().padLeft(2, '0');
    final secs = (rounded % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
}
