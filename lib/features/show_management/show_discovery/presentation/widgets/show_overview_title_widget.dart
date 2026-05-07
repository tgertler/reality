import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../favorites_management/presentation/providers/favorites_provider.dart';
import '../../../../favorites_management/presentation/widgets/favorite_heart_button.dart';

class ShowOverviewTitleWidget extends ConsumerWidget {
  final String showId;
  final String title;
  final String genre;
  final String headerImageUrl;
  final Color accentColor;
  final bool showTopActions;

  const ShowOverviewTitleWidget({
    super.key,
    required this.showId,
    required this.title,
    this.genre = '',
    this.headerImageUrl = '',
    this.accentColor = AppColors.pop,
    this.showTopActions = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasHeaderImage = headerImageUrl.trim().isNotEmpty;
    final normalizedGenre = genre.trim();
    final hasGenre = normalizedGenre.isNotEmpty;
    final countAsync = ref.watch(favoriteShowCountProvider(showId));

    return ClipRRect(
      child: Container(
        height: 310,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.black.withValues(alpha: 0.2), width: 1.2),
          ),
        ),
        child: Stack(
          children: [
            if (hasHeaderImage)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.18,
                  child: Image.network(
                    headerImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: hasHeaderImage ? 0.72 : 0.98),
                      Colors.white.withValues(alpha: 0.98),
                    ],
                  ),
                ),
              ),
            ),
            if (!hasHeaderImage)
              // Positioned(
              //   top: -40,
              //   right: -20,
              //   child: Container(
              //     width: 180,
              //     height: 180,
              //     decoration: BoxDecoration(
              //       shape: BoxShape.circle,
              //       color: widget.accentColor.withValues(alpha: 0.22),
              //     ),
              //   ),
              // ),
            if (!hasHeaderImage)
              Positioned(
                bottom: -50,
                left: -30,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.14),
                  ),
                ),
              ),
            if (showTopActions)
              Positioned(
                top: 44,
                left: 8,
                right: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Row(
                      children: [
                        FavoriteHeartButton(
                          showId: showId,
                          showTitle: title,
                          size: 24,
                          activeColor: accentColor,
                          inactiveColor: Colors.black54,
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.black54),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Positioned(
              bottom: 28,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    color: Colors.black,
                    child: Text(
                      'SHOW',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  countAsync.when(
                    data: (count) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              color: accentColor,
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '$count ${count == 1 ? 'Person' : 'Personen'} haben diese Show favorisiert',
                              style: GoogleFonts.dmSans(
                                color: Colors.black54,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (hasGenre) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Text(
                              normalizedGenre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                color: Colors.black54,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
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