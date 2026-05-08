import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/app_colors.dart';
import '../providers/premium_provider.dart';

class PaywallScreen extends ConsumerWidget {
  final String? sourceFeature;
  final String? sourceMessage;

  const PaywallScreen({
    super.key,
    this.sourceFeature,
    this.sourceMessage,
  });

  static Future<void> open(
    BuildContext context, {
    String? sourceFeature,
    String? sourceMessage,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaywallScreen(
          sourceFeature: sourceFeature,
          sourceMessage: sourceMessage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premiumState = ref.watch(premiumNotifierProvider);
    final sourceCopy = _sourceCopyFor(sourceFeature);
    final hintTitle = sourceCopy?.title;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F11),
      body: Column(
        children: [
          // ── White hero header (like ShowOverviewTitleWidget) ────────────
          _PaywallHero(
            topPadding: topPadding,
            onClose: () => Navigator.of(context).maybePop(),
          ),
          // ── Scrollable dark body ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.dmSans(
                        color: Colors.white60,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.55,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Die coolsten Features gibt\'s umsonst.\nDas hier ist das Extra obendrauf',
                        ),
                        if (hintTitle != null) ...[
                          const TextSpan(text: ' — für '),
                          TextSpan(
                            text: hintTitle,
                            style: GoogleFonts.dmSans(
                              color: AppColors.pop,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              height: 1.55,
                            ),
                          ),
                        ],
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ── Section label ──────────────────────────────────────────
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    //color: Colors.black,
                    child: Text(
                      'INBEGRIFFEN',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _FeatureTile(
                    icon: Icons.repeat_rounded,
                    title: 'Bingo Replay',
                    subtitle: 'Mehrere Sessions pro Event spielen',
                    highlighted: sourceFeature == 'bingo_replay',
                  ),
                  const SizedBox(height: 8),
                  _FeatureTile(
                    icon: Icons.live_tv_rounded,
                    title: 'Live Reactions',
                    subtitle: 'Emojis live während der Session senden',
                    highlighted: sourceFeature == 'bingo_reactions',
                  ),
                  const SizedBox(height: 8),
                  _FeatureTile(
                    icon: Icons.history_rounded,
                    title: 'Session-Historie',
                    subtitle: 'Alle Bingo-Sessions über alle Shows hinweg',
                    highlighted: sourceFeature == 'bingo_history',
                  ),
                  const SizedBox(height: 8),
                  _FeatureTile(
                    icon: Icons.bar_chart_rounded,
                    title: 'Persönliche Statistiken',
                    subtitle: 'Bingo-Rate, Bestzeiten, Top-Shows & mehr',
                    highlighted: sourceFeature == 'bingo_stats',
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // ── Sticky CTA ───────────────────────────────────────────────────
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  if (premiumState.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        premiumState.error!,
                        style: GoogleFonts.dmSans(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: premiumState.isLoading
                        ? null
                        : () async {
                            final ok = await ref
                                .read(premiumNotifierProvider.notifier)
                                .purchaseMonthly();
                            if (!context.mounted) return;
                            if (ok) {
                              Navigator.of(context).maybePop();
                            }
                          },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: AppColors.pop,
                        border: Border.all(color: Colors.black, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black, offset: Offset(3, 3)),
                        ],
                      ),
                      child: Center(
                        child: premiumState.isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                'JETZT FREISCHALTEN — 1,99 € / MONAT',
                                style: GoogleFonts.montserrat(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  letterSpacing: 0.6,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: premiumState.isLoading
                        ? null
                        : () async {
                            final ok = await ref
                                .read(premiumNotifierProvider.notifier)
                                .restore();
                            if (!context.mounted) return;
                            if (ok) {
                              Navigator.of(context).maybePop();
                            }
                          },
                    child: Text(
                      'Käufe wiederherstellen',
                      style: GoogleFonts.dmSans(
                        color: Colors.white38,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── White hero header (mirrors ShowOverviewTitleWidget) ──────────────────────

class _PaywallHero extends StatelessWidget {
  final double topPadding;
  final VoidCallback onClose;

  const _PaywallHero({required this.topPadding, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: topPadding + 210,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black, width: 2),
        ),
      ),
      child: Stack(
        children: [
          // Accent circle — bottom-left (same as title widget)
          Positioned(
            bottom: -55,
            left: -30,
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.pop.withValues(alpha: 0.18),
              ),
            ),
          ),
          // Second subtle circle — top-right
          Positioned(
            top: topPadding - 20,
            right: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ),
          // Close button — top-left, respects status bar
          Positioned(
            top: topPadding + 10,
            left: 16,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  // border: Border.fromBorderSide(
                  //   BorderSide(color: Colors.black, width: 2),
                  // ),
                  // boxShadow: [
                  //   BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                  // ],
                ),
                child:
                    const Icon(Icons.arrow_back, color: Colors.black, size: 25),
              ),
            ),
          ),
          // Main title block — bottom-left (same layout as ShowOverviewTitleWidget)
          Positioned(
            bottom: 22,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Container(
                //   padding: const EdgeInsets.symmetric(
                //     horizontal: 9,
                //     vertical: 4,
                //   ),
                //   color: Colors.black,
                //   child: Text(
                //     'PREMIUM',
                //     style: GoogleFonts.montserrat(
                //       color: Colors.white,
                //       fontSize: 11,
                //       fontWeight: FontWeight.w800,
                //       letterSpacing: 1.2,
                //     ),
                //   ),
                // ),
                const SizedBox(height: 8),
                Text(
                  'UNSCRIPTED\nPREMIUM',
                  style: GoogleFonts.montserrat(
                    color: Colors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Transform.rotate(
                  angle: -0.025,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFE600),
                      border: Border.fromBorderSide(
                        BorderSide(color: Colors.black, width: 2),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                      ],
                    ),
                    child: Text(
                      '1,99 € PRO MONAT',
                      style: GoogleFonts.montserrat(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaywallSourceCopy {
  final String title;
  final String subtitle;

  const _PaywallSourceCopy({
    required this.title,
    required this.subtitle,
  });
}

_PaywallSourceCopy? _sourceCopyFor(String? feature) {
  switch (feature) {
    case 'bingo_reactions':
      return const _PaywallSourceCopy(
        title: 'Live-Reactions',
        subtitle: 'Live-Emojis waehrend der Session sind Premium.',
      );
    case 'bingo_replay':
      return const _PaywallSourceCopy(
        title: 'Bingo Replay',
        subtitle: 'Mehrere Sessions pro Episode sind Premium.',
      );
    case 'bingo_history':
      return const _PaywallSourceCopy(
        title: 'Session-Historie',
        subtitle: 'Die globale Session-Historie ist Premium.',
      );
    case 'bingo_stats':
      return const _PaywallSourceCopy(
        title: 'Persoenliche Statistiken',
        subtitle: 'Persoenliche Bingo-Statistiken sind Premium.',
      );
    case 'premium_profile':
      return const _PaywallSourceCopy(
        title: 'Premium aus Profil',
        subtitle: 'Schalte Premium frei, um alle Extras zu nutzen.',
      );
    case 'premium_gate':
      return const _PaywallSourceCopy(
        title: 'Premium-Gesperrter Bereich',
        subtitle: 'Dieser Bereich ist Teil von Premium.',
      );
    case 'premium_tease':
      return const _PaywallSourceCopy(
        title: 'Premium-Preview',
        subtitle: 'Dieser Inhalt ist in Premium enthalten.',
      );
    default:
      return null;
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool highlighted;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: highlighted
            ? const Border(
                left: BorderSide(color: Color(0xFFFFE600), width: 4),
                top: BorderSide(color: Colors.black, width: 2),
                right: BorderSide(color: Colors.black, width: 2),
                bottom: BorderSide(color: Colors.black, width: 2),
              )
            : const Border.fromBorderSide(
                BorderSide(color: Colors.black, width: 2),
              ),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(2, 2)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(highlighted ? 12 : 12, 11, 12, 11),
        child: Row(
                children: [
                  Icon(
                    icon,
                    color: highlighted ? Colors.black : Colors.black54,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.montserrat(
                                color: Colors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (highlighted) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                color: Colors.black,
                                child: Text(
                                  'DAS WOLLTEST DU',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.dmSans(
                            color: Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}
