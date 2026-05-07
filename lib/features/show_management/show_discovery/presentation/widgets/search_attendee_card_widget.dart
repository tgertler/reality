import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class MainSearchAttendeeCard extends ConsumerWidget {
  final String title; // Name des Attendees
  final String id; // ID des Attendees

  const MainSearchAttendeeCard({
    super.key,
    required this.title,
    required this.id,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('${AppRoutes.attendeeOverview}/$id'),
      child: Padding(
        padding: const EdgeInsets.only(top: 8, left: 10, right: 10),
        child: Container(
          color: const Color(0xFF1A1A1A),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 46,
                color: Colors.white38,
              ),
              const SizedBox(width: 12),
              Container(
                width: 42,
                height: 42,
                color: Colors.black,
                child: const Icon(Icons.person_rounded, size: 22, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Teilnehmer',
                      style: GoogleFonts.dmSans(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
