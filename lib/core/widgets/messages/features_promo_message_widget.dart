import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class FeaturesPromoMessageWidget extends StatelessWidget {
  final VoidCallback onDismiss;

  const FeaturesPromoMessageWidget({
    super.key,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 20, 6),
      child: Dismissible(
        key: const ValueKey('features-promo-message'),
        direction: DismissDirection.horizontal,
        onDismissed: (_) => onDismiss(),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.fromLTRB(14, 12, 48, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: AppColors.pop,
                    child: const Icon(
                      Icons.notifications_active,
                      color: Color(0xFF1E1E1E),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEU: ERINNERUNGEN + FILTER',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.45,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Aktiviere Erinnerungen und filtere Inhalte nach deinen Streaming-Diensten in Mein Bereich.',
                          style: GoogleFonts.dmSans(
                            color: Colors.white54,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: onDismiss,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.close, size: 16, color: Colors.white30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
