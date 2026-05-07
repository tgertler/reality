/*This widget contains a card for a show plus the underlining title. The card should like the search result cards from Pocket Casts.*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class MainSearchShowCard extends ConsumerWidget {
  final String title; // Titel der Show
  final String id; // Titel der Show
  final String? genre;

  const MainSearchShowCard({
    super.key,
    required this.title,
    required this.id,
    this.genre,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('${AppRoutes.showOverview}/$id'),
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
                color: AppColors.pop,
              ),
              const SizedBox(width: 12),
              Container(
                width: 42,
                height: 42,
                color: Colors.black,
                child: const Icon(Icons.tv_rounded, size: 22, color: Colors.white),
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
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (genre?.trim().isNotEmpty ?? false)
                          ? 'Show · ${genre!.trim()}'
                          : 'Show',
                      style: GoogleFonts.dmSans(
                        color: AppColors.pop,
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
