import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/trash_event.dart';
import '../providers/trash_events_provider.dart';

class ShowTrashEventsSection extends ConsumerWidget {
  final String showId;
  final Color accentColor;

  const ShowTrashEventsSection({
    super.key,
    required this.showId,
    this.accentColor = const Color(0xFFFFD700),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(trashEventsProvider(showId));

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
                    //color: const Color.fromARGB(255, 255, 255, 255),
                    child: Text(
                      '🎉  TRASH & COMMUNITY EVENTS',
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
              ...events.map((e) => _TrashEventRow(event: e, accentColor: accentColor)),
            ],
          ),
        );
      },
    );
  }
}

// ─── Single trash event row ───────────────────────────────────────────────────

class _TrashEventRow extends StatelessWidget {
  final TrashEvent event;
  final Color accentColor;

  const _TrashEventRow({required this.event, required this.accentColor});

  Future<void> _openTickets() async {
    final url = event.externalUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final hasLink = event.externalUrl != null && event.externalUrl!.isNotEmpty;
    final hasLocation =
        event.location != null && event.location!.isNotEmpty;

    return GestureDetector(
      onTap: hasLink ? _openTickets : null,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: const Color.fromARGB(255, 0, 0, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Accent bar
            Container(
              width: 3,
              height: 44,
              color: accentColor,
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + optional price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (event.price != null && event.price!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              event.price!,
                              style: GoogleFonts.dmSans(
                                color: accentColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Location / organizer
                  if (hasLocation || event.organizer != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (hasLocation) ...[
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: Colors.white38),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              event.location!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        if (hasLocation &&
                            event.organizer != null &&
                            event.organizer!.isNotEmpty)
                          const Text(' · ',
                              style: TextStyle(
                                  color: Colors.white30, fontSize: 12)),
                        if (event.organizer != null &&
                            event.organizer!.isNotEmpty)
                          Flexible(
                            child: Text(
                              event.organizer!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],

                  // Description (optional)
                  if (event.description != null &&
                      event.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        color: Colors.white38,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Ticket arrow
            if (hasLink)
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 2),
                child: Icon(
                  Icons.open_in_new_rounded,
                  color: Colors.white24,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
