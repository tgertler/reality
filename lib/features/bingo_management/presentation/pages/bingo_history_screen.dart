import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/features/bingo_management/domain/entities/bingo_models.dart';
import 'package:frontend/features/bingo_management/presentation/providers/bingo_session_provider.dart';
import 'package:frontend/features/premium_management/presentation/pages/paywall_screen.dart';
import 'package:frontend/features/premium_management/presentation/providers/premium_provider.dart';
import 'package:intl/intl.dart';

class BingoHistoryScreen extends ConsumerWidget {
  const BingoHistoryScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const BingoHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premiumState = ref.watch(premiumNotifierProvider);
    final isPremium = premiumState.isPremium;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(onBack: () => Navigator.of(context).maybePop()),
            if (!isPremium)
              Expanded(
                child: _LockedView(
                  onUnlock: () => PaywallScreen.open(
                    context,
                    sourceFeature: 'bingo_history',
                  ),
                ),
              )
            else
              const Expanded(child: _HistoryBody()),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border.fromBorderSide(
                    BorderSide(color: Colors.black, width: 2)),
                boxShadow: [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
              ),
              child: const Icon(Icons.arrow_back, color: Colors.black, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session-Historie',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Alle abgeschlossenen Bingo-Sessions',
                  style: GoogleFonts.dmSans(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(
              color: Color(0xFFFFE600),
              border: Border.fromBorderSide(
                  BorderSide(color: Colors.black, width: 1.5)),
              boxShadow: [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
            ),
            child: Text(
              'PREMIUM',
              style: GoogleFonts.montserrat(
                color: Colors.black,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Locked state (not premium) ────────────────────────────────────────────────

class _LockedView extends StatelessWidget {
  final VoidCallback onUnlock;
  const _LockedView({required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.history_rounded,
                  color: Colors.white38, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'Session-Historie',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sieh dir alle deine vergangenen Bingo-Sessions über alle Shows hinweg an. Werde Premium um diese Funktion freizuschalten.',
              style: GoogleFonts.dmSans(
                color: Colors.white60,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: onUnlock,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 13, horizontal: 24),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE600),
                  border: Border.fromBorderSide(
                      BorderSide(color: Colors.black, width: 2)),
                  boxShadow: [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.black, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'PREMIUM FREISCHALTEN',
                      style: GoogleFonts.montserrat(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── History body (premium) ────────────────────────────────────────────────────

class _HistoryBody extends ConsumerWidget {
  const _HistoryBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(userBingoGlobalHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.pop),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Fehler beim Laden: $error',
            style: GoogleFonts.dmSans(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history_rounded,
                      color: Colors.white24, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Noch keine abgeschlossenen Sessions.',
                    style: GoogleFonts.dmSans(
                        color: Colors.white54, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Spiel dein erstes Bingo und beende die Session!',
                    style: GoogleFonts.dmSans(
                        color: Colors.white38, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) =>
              _HistoryTile(entry: entries[index]),
        );
      },
    );
  }
}

// ── Session tile ──────────────────────────────────────────────────────────────

class _HistoryTile extends StatelessWidget {
  final GlobalBingoHistoryEntry entry;
  const _HistoryTile({required this.entry});

  String get _episodeLabel {
    final ep = entry.episodeNumber;
    final se = entry.seasonNumber;
    if (ep == null) return '';
    if (se != null) return 'S${se.toString().padLeft(2, '0')} E${ep.toString().padLeft(2, '0')}';
    return 'Ep. $ep';
  }

  String get _dateLabel {
    final DateFormat fmt = DateFormat('dd.MM.yyyy');
    return fmt.format(entry.startedAt);
  }

  String _formatTime(double seconds) {
    final m = (seconds ~/ 60).toString();
    final s = (seconds.round() % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border(
          left: BorderSide(
            color: entry.bingoReached
                ? AppColors.pop.withValues(alpha: 0.8)
                : Colors.white24,
            width: 3,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stars column
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: i < entry.stars
                        ? const Color(0xFFFFE600)
                        : Colors.white12,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.showTitle,
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (entry.bingoReached)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          color: AppColors.pop,
                          child: Text(
                            'BINGO',
                            style: GoogleFonts.montserrat(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (_episodeLabel.isNotEmpty) ...[
                        Text(
                          _episodeLabel,
                          style: GoogleFonts.dmSans(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _dateLabel,
                        style: GoogleFonts.dmSans(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (entry.bingoReached &&
                      entry.timeToBingoSeconds != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _StatChip(
                          icon: Icons.timer_outlined,
                          label: _formatTime(entry.timeToBingoSeconds!),
                        ),
                        if (entry.fieldsAtBingo != null) ...[
                          const SizedBox(width: 6),
                          _StatChip(
                            icon: Icons.grid_3x3_rounded,
                            label: '${entry.fieldsAtBingo} Felder',
                          ),
                        ],
                        if (entry.score != null) ...[
                          const SizedBox(width: 6),
                          _StatChip(
                            icon: Icons.leaderboard_outlined,
                            label: entry.score!.toStringAsFixed(0),
                          ),
                        ],
                      ],
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
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white54),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
