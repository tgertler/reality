import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/features/bingo_management/domain/entities/bingo_models.dart';
import 'package:google_fonts/google_fonts.dart';

class BingoRunSummaryData {
  final bool bingoAchieved;
  final int stars;
  final String qualityLabel;
  final String title;
  final String subtitle;
  final String narrative;
  final String methodologyLabel;
  final String timeLabel;
  final String fieldsLabel;
  final String bingoLabel;
  final String modeLabel;
  final int? percentileBeat;

  const BingoRunSummaryData({
    required this.bingoAchieved,
    required this.stars,
    required this.qualityLabel,
    required this.title,
    required this.subtitle,
    required this.narrative,
    required this.methodologyLabel,
    required this.timeLabel,
    required this.fieldsLabel,
    required this.bingoLabel,
    required this.modeLabel,
    this.percentileBeat,
  });

  factory BingoRunSummaryData.fromSession({
    required BingoSessionView session,
    required BingoSessionStatsView? stats,
  }) {
    final bingoAchieved = stats?.bingoAchieved ?? session.bingoReached;
    final fieldsAtBingo = stats?.fieldsAtBingo ?? (bingoAchieved ? session.checkedCount : null);

    final rawSeconds = stats?.timeToBingoSeconds;
    final fallbackSeconds = bingoAchieved
        ? (session.endedAt ?? DateTime.now()).difference(session.startedAt).inSeconds.toDouble()
        : null;
    final seconds = rawSeconds ?? fallbackSeconds;

    final evaluation = _evaluateRun(
      bingoAchieved: bingoAchieved,
      timeToBingoSeconds: seconds,
      fieldsAtBingo: fieldsAtBingo,
    );

    return BingoRunSummaryData(
      bingoAchieved: bingoAchieved,
      stars: evaluation.stars,
      qualityLabel: evaluation.qualityLabel,
      title: bingoAchieved ? 'Bingo! 🎉' : 'Kein Bingo',
      subtitle: evaluation.subtitle,
      narrative: _narrative(
        focusLabel: evaluation.focusLabel,
        paceHint: evaluation.paceHint,
        stars: evaluation.stars,
        bingoAchieved: bingoAchieved,
      ),
      methodologyLabel: '',
      timeLabel: _formatDuration(seconds),
      fieldsLabel: fieldsAtBingo != null
          ? '$fieldsAtBingo genutzt'
          : '${session.checkedCount} genutzt',
      bingoLabel: bingoAchieved ? 'Ja' : 'Nein',
      modeLabel: _formatMode(session.mode),
      percentileBeat: bingoAchieved ? _calcPercentile(seconds, fieldsAtBingo) : null,
    );
  }

  static _RunEvaluation _evaluateRun({
    required bool bingoAchieved,
    required double? timeToBingoSeconds,
    required int? fieldsAtBingo,
  }) {
    if (!bingoAchieved) {
      return const _RunEvaluation(
        stars: 1,
        qualityLabel: 'Kein Bingo',
        subtitle: 'Nächstes Mal klappts!',
        focusLabel: 'Offen',
        paceHint: 'Neutral',
      );
    }

    final seconds = timeToBingoSeconds ?? 99999;
    final fields = fieldsAtBingo ?? 99;

    final focusBand = _focusBand(fields);
    final paceBand = _paceBand(seconds);
    final totalPoints = focusBand.points + paceBand.points;

    final stars = totalPoints >= 5
        ? 3
        : totalPoints >= 3
            ? 2
            : 1;

    final subtitle = 'Starke Leistung';

    return _RunEvaluation(
      stars: stars,
      qualityLabel: _qualityLabel(stars),
      subtitle: subtitle,
      focusLabel: focusBand.label,
      paceHint: paceBand.label,
    );
  }

  static String _qualityLabel(int stars) {
    if (stars >= 3) return 'Sehr stark';
    if (stars == 2) return 'Solide';
    return 'Lern-Run';
  }

  static String _narrative({
    required String focusLabel,
    required String paceHint,
    required int stars,
    required bool bingoAchieved,
  }) {
    if (!bingoAchieved) {
      return 'Leider kein Bingo in diesem Run.';
    }

    if (stars >= 3) {
      return 'Sehr gute Aufmerksamkeit. Unsere Einschätzung: $paceHint.';
    }
    if (stars == 2) {
      return 'Solider Run mit $focusLabel Fokus.';
    }
    return 'Bingo erreicht, aber mit breiter Streuung. Fokus: $focusLabel, Verlauf: $paceHint.';
  }

  static _Band _focusBand(int fields) {
    if (fields <= 7) return const _Band(label: 'Präzise', points: 4);
    if (fields <= 9) return const _Band(label: 'Gezielt', points: 3);
    if (fields <= 12) return const _Band(label: 'Stabil', points: 2);
    if (fields <= 15) return const _Band(label: 'Breit', points: 1);
    return const _Band(label: 'Streuend', points: 0);
  }

  static int _calcPercentile(double? seconds, int? fields) {
    final focusPts = _focusBand(fields ?? 99).points;
    final pacePts = _paceBand(seconds ?? 99999).points;
    final total = focusPts + pacePts;
    if (total >= 5) return 95;
    if (total == 4) return 82;
    if (total == 3) return 65;
    if (total == 2) return 45;
    if (total == 1) return 28;
    if (total == 0) return 15;
    return 5;
  }

  static _Band _paceBand(double seconds) {
    // Pace-Bands orientiert an einer typischen 60-Minuten-Folge.
    if (seconds <= 20 * 60) return const _Band(label: 'Sehr schnelle Auffassungsgabe', points: 2);
    if (seconds <= 35 * 60) return const _Band(label: 'Schnelle Auffassungsgabe', points: 1);
    if (seconds <= 60 * 60) return const _Band(label: 'Solides Tempo', points: 0);
    return const _Band(label: 'Eher gemuetliches Tempo', points: -1);
  }

  static String _formatDuration(double? seconds) {
    if (seconds == null || seconds.isNaN || seconds.isInfinite || seconds < 0) {
      return '-- min';
    }
    final roundedMinutes = (seconds / 60).round();
    if (roundedMinutes <= 0) return '<1 min';
    return '$roundedMinutes min';
  }

  static String _formatMode(String mode) {
    final normalized = mode.trim().toUpperCase();
    switch (normalized) {
      case 'WATCHPARTY':
        return 'Watchparty';
      default:
        return normalized.isEmpty ? 'Unbekannt' : normalized;
    }
  }
}

class BingoRunSummarySheet extends StatelessWidget {
  final BingoRunSummaryData data;
  final VoidCallback onPlayAgain;
  final VoidCallback onViewRuns;
  final VoidCallback onViewRanking;
  final bool embedded;
  final bool showPercentileSection;

  const BingoRunSummarySheet({
    super.key,
    required this.data,
    required this.onPlayAgain,
    required this.onViewRuns,
    required this.onViewRanking,
    this.embedded = false,
    this.showPercentileSection = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(0, 0, 0, embedded ? 8 : 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!embedded)
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          if (!embedded) const SizedBox(height: 18),
          if (embedded) ...[
            const SizedBox(height: 0),
            _StarsPanel(data: data, lightBackground: true),
            const SizedBox(height: 20),
            _CompactStatsRow(data: data, lightBackground: true),
            if (showPercentileSection && data.percentileBeat != null) ...[
              const SizedBox(height: 24),
              _PercentileHero(percentile: data.percentileBeat!, lightBackground: true),
            ],
            const SizedBox(height: 14),
            
            //_FazitLine(narrative: data.narrative, lightBackground: true),
            //const SizedBox(height: 20),
            //const _ShareFooter(lightBackground: true),
          ] else ...[
            //_Header(data: data),
            const SizedBox(height: 16),
            _StarsPanel(data: data),
            const SizedBox(height: 14),
            _StatsGrid(data: data),
            if (data.percentileBeat != null) ...[const SizedBox(height: 12), _PercentileCard(percentile: data.percentileBeat!)],
            const SizedBox(height: 12),
            //_NarrativeCard(data: data),
            _ActionButtons(
              data: data,
              onPlayAgain: onPlayAgain,
              onViewRuns: onViewRuns,
              onViewRanking: onViewRanking,
            ),
          ],
        ],
      ),
    );

    if (embedded) {
      return Container(
        decoration: BoxDecoration(
          //color: const Color(0xFF0D0D10),
          //border: Border.all(color: Colors.white12),
        ),
        child: content,
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D10),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(top: false, child: content),
    );
  }
}

class _StarsPanel extends StatelessWidget {
  final BingoRunSummaryData data;
  final bool lightBackground;

  const _StarsPanel({required this.data, this.lightBackground = false});

  @override
  Widget build(BuildContext context) {
    final labelBorderColor = lightBackground
        ? Colors.black
        : const Color(0xFFFFD700).withValues(alpha: 0.5);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _AnimatedStars(stars: data.stars, lightBackground: lightBackground),
          const SizedBox(height: 14),
          Center(
            child: Transform.translate(
              offset: lightBackground ? const Offset(4, 0) : Offset.zero,
              child: Transform.rotate(
                angle: 0.008,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: lightBackground ? Colors.black : Colors.transparent,
                    border: Border.all(
                      color: labelBorderColor,
                      width: 1.5,
                    ),
                    boxShadow: lightBackground
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              offset: const Offset(3, 3),
                              blurRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    data.qualityLabel.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      color: lightBackground ? Colors.white : const Color(0xFFFFD700),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedStars extends StatefulWidget {
  final int stars;
  final bool lightBackground;

  const _AnimatedStars({required this.stars, this.lightBackground = false});

  @override
  State<_AnimatedStars> createState() => _AnimatedStarsState();
}

class _AnimatedStarsState extends State<_AnimatedStars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const starColor = Color(0xFFEFBF04);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final start = index * 0.22;
            const window = 0.48;
            final progress = ((_controller.value - start) / window).clamp(0.0, 1.0);
            final eased = Curves.easeOutBack.transform(progress);
            final opacity = (progress * 3).clamp(0.0, 1.0);
            final filled = index < widget.stars;

            return Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: eased,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (filled)
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                starColor.withValues(alpha: 0.38),
                                starColor.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      Icon(
                        filled ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 56,
                        color: filled
                            ? starColor
                            : (widget.lightBackground
                                ? Colors.black26
                                : Colors.white24),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final BingoRunSummaryData data;

  const _StatsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131316),
        border: Border.all(color: Colors.white12),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _StatItem(
              icon: Icons.timer_outlined,
              label: 'Zeit',
              value: data.timeLabel,
            ),
            const VerticalDivider(width: 1, thickness: 1, color: Colors.white12),
            _StatItem(
              icon: Icons.grid_view_rounded,
              label: 'Felder',
              value: data.fieldsLabel,
            ),
            const VerticalDivider(width: 1, thickness: 1, color: Colors.white12),
            _StatItem(
              icon: Icons.check_circle_outline_rounded,
              label: 'Bingo',
              value: data.bingoLabel,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.pop.withValues(alpha: 0.75), size: 12),
                const SizedBox(width: 5),
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PercentileCard extends StatelessWidget {
  final int percentile;

  const _PercentileCard({required this.percentile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1017),
        border: Border(
          left: BorderSide(color: Color.fromARGB(255, 134, 134, 134), width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DU BIST BESSER ALS',
                  style: GoogleFonts.montserrat(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'aller Bingo-Runs',
                  style: GoogleFonts.dmSans(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'berechnet aus Tempo & Feldnutzung',
                  style: GoogleFonts.dmSans(
                    color: Colors.white24,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$percentile%',
            style: GoogleFonts.montserrat(
              color: AppColors.pop,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final BingoRunSummaryData data;
  final VoidCallback onPlayAgain;
  final VoidCallback onViewRuns;
  final VoidCallback onViewRanking;

  const _ActionButtons({
    required this.data,
    required this.onPlayAgain,
    required this.onViewRuns,
    required this.onViewRanking,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          // child: ElevatedButton.icon(
          //   onPressed: onPlayAgain,
          //   icon: const Icon(Icons.refresh_rounded),
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: AppColors.pop,
          //     foregroundColor: const Color(0xFF1E1E1E),
          //     padding: const EdgeInsets.symmetric(vertical: 12),
          //   ),
          //   label: Text(
          //     'Nochmal spielen',
          //     style: GoogleFonts.montserrat(
          //       fontWeight: FontWeight.w800,
          //       fontSize: 13,
          //     ),
          //   ),
          // ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onViewRuns,
            icon: const Icon(Icons.bar_chart_rounded),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ),
            label: Text(
              'Meine Runs ansehen',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // SizedBox(
        //   width: double.infinity,
        //   child: OutlinedButton.icon(
        //     onPressed: () async {
        //       try {
        //         await Share.share(_buildShareText());
        //       } catch (_) {
        //         await Clipboard.setData(ClipboardData(text: _buildShareText()));
        //         if (context.mounted) {
        //           ScaffoldMessenger.of(context).showSnackBar(
        //             const SnackBar(
        //               content: Text('In Zwischenablage kopiert!'),
        //               duration: Duration(seconds: 2),
        //             ),
        //           );
        //         }
        //       }
        //     },
        //     icon: const Icon(Icons.ios_share_rounded),
        //     style: OutlinedButton.styleFrom(
        //       side: BorderSide(color: AppColors.pop.withValues(alpha: 0.6)),
        //       foregroundColor: AppColors.pop,
        //       padding: const EdgeInsets.symmetric(vertical: 12),
        //       shape: const RoundedRectangleBorder(
        //         borderRadius: BorderRadius.all(Radius.circular(4)),
        //       ),
        //     ),
        //     label: Text(
        //       'Run teilen',
        //       style: GoogleFonts.dmSans(
        //         fontWeight: FontWeight.w700,
        //         fontSize: 13,
        //       ),
        //     ),
        //   ),
        // ),
        // const SizedBox(height: 8),
        // SizedBox(
        //   width: double.infinity,
        //   child: TextButton.icon(
        //     onPressed: onViewRanking,
        //     icon: const Icon(Icons.emoji_events_outlined),
        //     style: TextButton.styleFrom(
        //       foregroundColor: Colors.white70,
        //       padding: const EdgeInsets.symmetric(vertical: 10),
        //     ),
        //     label: Text(
        //       'Ranking ansehen',
        //       style: GoogleFonts.dmSans(
        //         fontWeight: FontWeight.w700,
        //         fontSize: 13,
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }
}

// ── Embedded-only widgets ────────────────────────────────────────────────────

class _CompactStatsRow extends StatelessWidget {
  final BingoRunSummaryData data;
  final bool lightBackground;

  const _CompactStatsRow({required this.data, this.lightBackground = false});

  @override
  Widget build(BuildContext context) {
    final textColor = lightBackground ? Colors.black54 : Colors.white60;
    final iconColor = lightBackground ? Colors.black38 : Colors.white38;
    final style = GoogleFonts.dmSans(
      color: textColor,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_outlined, size: 13, color: iconColor),
          const SizedBox(width: 4),
          Text(data.timeLabel, style: style),
          const SizedBox(width: 16),
          Icon(Icons.grid_view_rounded, size: 13, color: iconColor),
          const SizedBox(width: 4),
          Text(data.fieldsLabel, style: style),
          const SizedBox(width: 16),
          Icon(Icons.check_circle_outline_rounded, size: 13, color: iconColor),
          const SizedBox(width: 4),
          Text(data.bingoLabel, style: style),
        ],
      ),
    );
  }
}

class _PercentileHero extends StatelessWidget {
  final int percentile;
  final bool lightBackground;

  const _PercentileHero({required this.percentile, this.lightBackground = false});

  @override
  Widget build(BuildContext context) {
    final labelColor = lightBackground ? Colors.black45 : Colors.white38;
    final percentileColor = lightBackground ? AppColors.secondary : AppColors.pop;
    final subColor = lightBackground ? Colors.black54 : Colors.white54;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BESSER ALS',
            style: GoogleFonts.montserrat(
              color: labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$percentile %',
                style: GoogleFonts.montserrat(
                  color: percentileColor,
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2.0,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'ALLER RUNS',
                  style: GoogleFonts.montserrat(
                    color: subColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RunEvaluation {
  final int stars;
  final String qualityLabel;
  final String subtitle;
  final String focusLabel;
  final String paceHint;

  const _RunEvaluation({
    required this.stars,
    required this.qualityLabel,
    required this.subtitle,
    required this.focusLabel,
    required this.paceHint,
  });
}

class _Band {
  final String label;
  final int points;

  const _Band({required this.label, required this.points});
}
