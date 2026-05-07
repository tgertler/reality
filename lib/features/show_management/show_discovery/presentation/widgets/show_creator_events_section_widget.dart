import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/creator_event.dart';
import '../providers/creator_events_provider.dart';

class ShowCreatorEventsSection extends ConsumerWidget {
  final String showId;
  final Color accentColor;

  const ShowCreatorEventsSection({
    super.key,
    required this.showId,
    this.accentColor = AppColors.pop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(creatorEventsProvider(showId));

    return eventsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (events) {
        if (events.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section header ─────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    //color: const Color.fromARGB(255, 189, 76, 76),
                    child: Text(
                      '🎥  REACTIONS & CREATOR CONTENT',
                      style: GoogleFonts.montserrat(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Event rows ─────────────────────────────────────────────
              ...events.map((e) => _CreatorEventRow(event: e, accentColor: accentColor)),
            ],
          ),
        );
      },
    );
  }
}

// ─── Single creator event row ─────────────────────────────────────────────────

class _CreatorEventRow extends StatelessWidget {
  final CreatorEvent event;
  final Color accentColor;

  const _CreatorEventRow({required this.event, required this.accentColor});

  Future<void> _open() async {
    final url = event.youtubeUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final hasLink = event.youtubeUrl != null && event.youtubeUrl!.isNotEmpty;

    return GestureDetector(
      onTap: hasLink ? _open : null,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: const Color.fromARGB(255, 0, 0, 0),
        child: Row(
          children: [
            // Kind accent bar
            Container(
              width: 3,
              height: 36,
              color: accentColor,
            ),
            const SizedBox(width: 12),

            // Thumbnail placeholder
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 33, 33, 33),
                borderRadius: BorderRadius.circular(6),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: event.thumbnailUrl != null &&
                        event.thumbnailUrl!.isNotEmpty
                    ? Image.network(
                        event.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholderIcon(),
                      )
                    : _placeholderIcon(),
              ),
            ),

            const SizedBox(width: 12),

            // Text block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Creator name + kind badge
                  Row(
                    children: [
                      if (event.creator?.name.isNotEmpty == true)
                        Flexible(
                          child: Text(
                            event.creator!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          event.kindLabel,
                          style: GoogleFonts.dmSans(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    event.displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow / play icon
            if (hasLink)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.play_circle_outline_rounded,
                  color: Colors.white24,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return const Center(
      child: Icon(Icons.play_arrow_rounded, color: Colors.white30, size: 22),
    );
  }
}
