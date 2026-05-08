import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/features/bingo_management/domain/entities/bingo_models.dart';
import 'package:frontend/features/bingo_management/presentation/providers/bingo_session_provider.dart';
import 'package:frontend/features/premium_management/presentation/pages/paywall_screen.dart';
import 'package:frontend/features/premium_management/presentation/providers/premium_provider.dart';

class BingoPersonalStatsScreen extends ConsumerWidget {
  const BingoPersonalStatsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
          builder: (_) => const BingoPersonalStatsScreen()),
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
                            sourceFeature: 'bingo_stats',
                          )))
            else
              const Expanded(child: _StatsBody()),
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
                  'Meine Statistiken',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Persönliche Bingo-Auswertung',
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

// ── Locked state ──────────────────────────────────────────────────────────────

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
              child: const Icon(Icons.bar_chart_rounded,
                  color: Colors.white38, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'Persönliche Statistiken',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Deine persönliche Bingo-Auswertung: Bingo-Rate, Bestzeiten, Top-Shows und mehr. Werde Premium um diese Funktion freizuschalten.',
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
                    const Icon(Icons.star_rounded, color: Colors.black, size: 16),
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

// ── Stats body ────────────────────────────────────────────────────────────────

class _StatsBody extends ConsumerWidget {
  const _StatsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userBingoStatsProvider);

    return statsAsync.when(
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
      data: (stats) {
        if (stats.totalSessions == 0) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bar_chart_rounded,
                      color: Colors.white24, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Noch keine Statistiken vorhanden.',
                    style: GoogleFonts.dmSans(
                        color: Colors.white54, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Beende deine erste Bingo-Session um Statistiken zu sehen!',
                    style: GoogleFonts.dmSans(
                        color: Colors.white38, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return _StatsContent(stats: stats);
      },
    );
  }
}

class _StatsContent extends StatelessWidget {
  final UserBingoStatsView stats;
  const _StatsContent({required this.stats});

  String _formatTime(double seconds) {
    final m = (seconds ~/ 60).toString();
    final s = (seconds.round() % 60).toString().padLeft(2, '0');
    return '$m:$s min';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        // ── Summary row ──────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _BigStatTile(
                label: 'Sessions',
                value: stats.totalSessions.toString(),
                icon: Icons.sports_esports_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BigStatTile(
                label: 'Bingos',
                value: stats.totalBingos.toString(),
                icon: Icons.check_circle_outline_rounded,
                highlight: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _BigStatTile(
                label: 'Bingo-Rate',
                value: '${stats.bingoRate.toStringAsFixed(0)} %',
                icon: Icons.percent_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // ── Detail row ───────────────────────────────────────────────────────
        Row(
          children: [
            if (stats.bestTimeSeconds != null)
              Expanded(
                child: _DetailTile(
                  label: 'Beste Zeit',
                  value: _formatTime(stats.bestTimeSeconds!),
                  icon: Icons.timer_outlined,
                ),
              ),
            if (stats.bestTimeSeconds != null) const SizedBox(width: 10),
            Expanded(
              child: _DetailTile(
                label: 'Avg. Score',
                value: stats.avgScore.toStringAsFixed(1),
                icon: Icons.leaderboard_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DetailTile(
                label: 'Top Score',
                value: stats.topScore.toStringAsFixed(0),
                icon: Icons.emoji_events_outlined,
              ),
            ),
          ],
        ),
        if (stats.avgFieldsAtBingo > 0) ...[
          const SizedBox(height: 10),
          _DetailTile(
            label: 'Ø Felder bei Bingo',
            value: stats.avgFieldsAtBingo.toStringAsFixed(1),
            icon: Icons.grid_3x3_rounded,
            fullWidth: true,
          ),
        ],
        // ── Top shows ────────────────────────────────────────────────────────
        if (stats.topShows.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'TOP SHOWS',
            style: GoogleFonts.montserrat(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          ...stats.topShows.map((show) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ShowStatRow(show: show,
                    maxCount: stats.topShows.first.sessionCount),
              )),
        ],
      ],
    );
  }
}

// ── Big stat tile ─────────────────────────────────────────────────────────────

class _BigStatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _BigStatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.pop.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: highlight ? AppColors.pop.withValues(alpha: 0.5) : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 18,
              color: highlight ? AppColors.pop : Colors.white38),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: highlight ? AppColors.pop : Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail tile ───────────────────────────────────────────────────────────────

class _DetailTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool fullWidth;

  const _DetailTile({
    required this.label,
    required this.value,
    required this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white38),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: Colors.white38,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (fullWidth) return content;
    return content;
  }
}

// ── Show stat row (horizontal bar) ────────────────────────────────────────────

class _ShowStatRow extends StatelessWidget {
  final UserBingoStatsTopShow show;
  final int maxCount;

  const _ShowStatRow({required this.show, required this.maxCount});

  @override
  Widget build(BuildContext context) {
    final fraction =
        maxCount > 0 ? show.sessionCount / maxCount : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                show.showTitle,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${show.sessionCount} Sessions · ${show.bingoCount} Bingos',
              style: GoogleFonts.dmSans(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: fraction.clamp(0.05, 1.0),
            child: Container(
              height: 4,
              color: AppColors.pop.withValues(alpha: 0.7),
            ),
          ),
        ),
        // Full-width background track
        FractionallySizedBox(
          widthFactor: 1.0,
          child: Container(
            height: 1,
            color: Colors.white10,
          ),
        ),
      ],
    );
  }
}
