import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class TrashCalendarWidget extends StatelessWidget {
  final VoidCallback onClose;

  const TrashCalendarWidget({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 4),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.pop,
            padding: const EdgeInsets.fromLTRB(14, 12, 48, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.black,
                  child: const Icon(
                    Icons.calendar_month,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TRASH-KALENDER',
                        style: GoogleFonts.montserrat(
                          color: const Color(0xFF1E1E1E),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Ist jetzt für dich verfügbar. Probiere es aus!',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
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
              onTap: onClose,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.close, size: 16, color: Colors.black38),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
