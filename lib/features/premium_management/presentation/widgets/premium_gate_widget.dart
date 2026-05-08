import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../pages/paywall_screen.dart';
import '../providers/premium_provider.dart';

class PremiumGateWidget extends ConsumerWidget {
  final Widget child;
  final String lockedTitle;
  final String lockedSubtitle;

  const PremiumGateWidget({
    super.key,
    required this.child,
    this.lockedTitle = 'PREMIUM',
    this.lockedSubtitle = 'Tippe zum Freischalten',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    if (isPremium) {
      return child;
    }

    return Stack(
      children: [
        Opacity(opacity: 0.35, child: child),
        Positioned.fill(
          child: Material(
            color: Colors.black.withValues(alpha: 0.42),
            child: InkWell(
              onTap: () => PaywallScreen.open(
                context,
                sourceFeature: 'premium_gate',
              ),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.black, width: 2),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black, offset: Offset(2, 2)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lockedTitle,
                        style: GoogleFonts.montserrat(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lockedSubtitle,
                        style: GoogleFonts.dmSans(
                          color: Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
