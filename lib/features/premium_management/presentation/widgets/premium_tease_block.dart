import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/premium_waitlist_provider.dart';
import 'package:frontend/features/user_management/presentation/providers/user_provider.dart';

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
    final waitlistState = ref.watch(premiumWaitlistNotifierProvider);

    // Trigger status check once user is known
    if (user != null && !waitlistState.hasChecked && !waitlistState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(premiumWaitlistNotifierProvider.notifier).checkStatus(user.id);
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
                    'PREMIUM KOMMT BALD',
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
                  : _WaitlistButton(
                      userId: user.id,
                      isOnWaitlist: waitlistState.isOnWaitlist,
                      isLoading: waitlistState.isLoading,
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

class _WaitlistButton extends ConsumerWidget {
  final String userId;
  final bool isOnWaitlist;
  final bool isLoading;

  const _WaitlistButton({
    required this.userId,
    required this.isOnWaitlist,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isOnWaitlist) {
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
              'Du bist vorgemerkt',
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
      onTap: isLoading
          ? null
          : () => ref
              .read(premiumWaitlistNotifierProvider.notifier)
              .joinWaitlist(userId),
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
                isLoading ? 'Wird eingetragen…' : 'FÜR PREMIUM VORMERKEN',
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
      'Melde dich an, um dich vorzumerken',
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
    final state = ref.watch(premiumWaitlistNotifierProvider);

    if (!state.hasChecked && !state.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(premiumWaitlistNotifierProvider.notifier).checkStatus(userId);
      });
    }

    if (state.isLoading && !state.hasChecked) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF9C4DFF)),
      );
    }

    if (state.isOnWaitlist) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        color: const Color(0xFF9C4DFF).withValues(alpha: 0.18),
        child: Text(
          '✅ Vorgemerkt',
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
        'Noch nicht vorgemerkt',
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
