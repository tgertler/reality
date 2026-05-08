import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/features/user_management/presentation/providers/user_provider.dart';
import '../pages/paywall_screen.dart';
import '../providers/premium_provider.dart';

// ── PremiumTeaseBlock ─────────────────────────────────────────────────────────
//
// Ein "locked preview" Container der angedeutete Premium-Stats anzeigt und
// einen Join-Waitlist-CTA enthält. Kann überall eingebettet werden.
//
// Beispiel:
//   PremiumTeaseBlock(
//     lockedItems: [
//       PremiumLockedItem(emoji: '⚡', label: 'Bearbeitungstyp: Schnell wie der Blitz'),
//       PremiumLockedItem(emoji: '🎯', label: 'Spielstil: Risikofreudig'),
//       PremiumLockedItem(emoji: '📊', label: 'Effizienz-Score'),
//     ],
//   )

class PremiumLockedItem {
  final String emoji;
  final String label;
  const PremiumLockedItem({required this.emoji, required this.label});
}

class PremiumTeaseBlock extends ConsumerWidget {
  final List<PremiumLockedItem> lockedItems;

  const PremiumTeaseBlock({super.key, required this.lockedItems});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userNotifierProvider).user;
    final premiumState = ref.watch(premiumNotifierProvider);
    final profile = ref.watch(userNotifierProvider).profile;
    final isPremium = premiumState.isPremium || (profile?.isPremium ?? false);

    if (user != null && !premiumState.hasChecked && !premiumState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(premiumNotifierProvider.notifier).refreshStatus();
      });
    }

    return Transform.rotate(
      angle: -0.012,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border.fromBorderSide(
            BorderSide(color: Colors.black, width: 3),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black, offset: Offset(6, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header badge ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              color: const Color(0xFFFFE600),
              child: Row(
                children: [
                  // const Text('✨', style: TextStyle(fontSize: 13)),
                  // const SizedBox(width: 8),
                  Text(
                    isPremium ? 'UNSCRIPTED Premium AKTIV' : 'UNSCRIPTED Premium',
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            // ── Locked item rows ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Column(
                children:
                    lockedItems.map((item) => _LockedRow(item: item)).toList(),
              ),
            ),
            // ── CTA ──────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: user == null
                  ? _NotLoggedInHint()
                  : _PremiumButton(
                      isPremium: isPremium,
                      isLoading: premiumState.isLoading,
                      onTap: () async {
                        if (isPremium) return;
                        await PaywallScreen.open(
                          context,
                          sourceFeature: 'premium_tease',
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _LockedRow ─────────────────────────────────────────────────────────────────

class _LockedRow extends StatelessWidget {
  final PremiumLockedItem item;
  const _LockedRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(
              children: [
                // blurred label text
                Text(
                  item.label,
                  style: GoogleFonts.dmSans(
                    color: Colors.black.withValues(alpha: 0.50),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // frosted overlay strip
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.88),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.lock_outline_rounded,
              size: 14, color: Colors.black45),
        ],
      ),
    );
  }
}

// ── _WaitlistButton ────────────────────────────────────────────────────────────

class _PremiumButton extends StatelessWidget {
  final bool isPremium;
  final bool isLoading;
  final VoidCallback onTap;

  const _PremiumButton({
    required this.isPremium,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
        decoration: const BoxDecoration(
          color: Color(0xFFFFE600),
          border: Border.fromBorderSide(
            BorderSide(color: Colors.black, width: 2),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black, offset: Offset(3, 3)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.black, size: 16),
            const SizedBox(width: 8),
            Text(
              'Premium ist aktiv',
              style: GoogleFonts.montserrat(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Transform.rotate(
        angle: 0.01,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: const BoxDecoration(
            color: Colors.black,
            border: Border.fromBorderSide(
              BorderSide(color: Colors.black, width: 2),
            ),
            boxShadow: [
              BoxShadow(color: Color(0xFFFFE600), offset: Offset(4, 4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFFFFE600)),
                )
              else
                const Icon(Icons.star_border_rounded,
                    size: 16, color: Color(0xFFFFE600)),
              const SizedBox(width: 8),
              Text(
                isLoading ? 'Wird geladen...' : 'JETZT HOLEN',
                style: GoogleFonts.montserrat(
                  color: const Color(0xFFFFE600),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _NotLoggedInHint ───────────────────────────────────────────────────────────

class _NotLoggedInHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Melde dich an, um Premium freizuschalten',
      style: GoogleFonts.dmSans(
        color: Colors.black45,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ── PremiumStatusBadge ─────────────────────────────────────────────────────────
//
// Inline-Badge für die User-Page: zeigt Waitlist-Status

class PremiumStatusBadge extends ConsumerWidget {
  final String userId;
  const PremiumStatusBadge({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(premiumNotifierProvider);

    if (!state.hasChecked && !state.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(premiumNotifierProvider.notifier).refreshStatus();
      });
    }

    if (state.isLoading) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF9C4DFF)),
      );
    }

    if (state.isPremium) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        color: const Color(0xFF9C4DFF).withValues(alpha: 0.18),
        child: Text(
          '✅ Premium',
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFCC99FF),
            letterSpacing: 0.8,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: Colors.white.withValues(alpha: 0.06),
      child: Text(
        'Kostenlos',
        style: GoogleFonts.montserrat(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white38,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
