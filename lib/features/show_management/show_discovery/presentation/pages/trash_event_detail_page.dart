import 'package:flutter/material.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/features/calendar_management/domain/entities/resolved_calendar_event.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class TrashEventDetailPage extends StatelessWidget {
  final ResolvedCalendarEvent event;
  const TrashEventDetailPage({super.key, required this.event});
  static const _gold = Color(0xFFFFD700);

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final timeFormatted = DateFormat('EEEE, dd. MMMM yyyy \u00b7 HH:mm', 'de_DE')
        .format(event.startDatetime.toLocal());
    final title = event.trashEventTitle ?? 'Community Event';
    final description = event.trashEventDescription;
    final hasExternal = event.trashEventExternalUrl != null;
    final hasRelatedShow = event.trashRelatedShowId != null && event.trashRelatedShowId!.isNotEmpty;
    final hasDetails = event.trashEventLocation != null || event.trashEventAddress != null ||
        event.trashEventOrganizer != null || event.trashEventPrice != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFFE6FF),
      body: Container(
        decoration: const BoxDecoration(
          color: Color.fromARGB(255, 255, 255, 255),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _HeroHeader(
              accentColor: _gold,
              badgeLabel: 'COMMUNITY EVENT',
              title: title,
              imageUrl: event.trashEventImageUrl,
              timeFormatted: timeFormatted,
            ),
            const SizedBox(height: 12),
            if (hasDetails)
              _ContentBlock(
                label: 'DETAILS',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (event.trashEventLocation != null)
                      _DetailRow(icon: Icons.location_on_rounded, text: event.trashEventLocation!),
                    if (event.trashEventAddress != null) ...[
                      const SizedBox(height: 8),
                      _DetailRow(icon: Icons.map_rounded, text: event.trashEventAddress!),
                    ],
                    if (event.trashEventOrganizer != null) ...[
                      const SizedBox(height: 8),
                      _DetailRow(icon: Icons.person_rounded, text: event.trashEventOrganizer!),
                    ],
                    if (event.trashEventPrice != null) ...[
                      const SizedBox(height: 8),
                      _DetailRow(icon: Icons.euro_rounded, text: event.trashEventPrice!, highlight: true),
                    ],
                  ],
                ),
              ),
            if (description != null && description.isNotEmpty)
              _ContentBlock(
                label: 'BESCHREIBUNG',
                child: Text(description,
                    style: GoogleFonts.dmSans(fontSize: 14, color: Colors.white70, height: 1.6)),
              ),
            if (hasExternal)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: GestureDetector(
                  onTap: () => _launchUrl(event.trashEventExternalUrl!),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: _gold,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.open_in_new_rounded, color: Colors.black, size: 18),
                      const SizedBox(width: 8),
                      Text('MEHR INFOS',
                          style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w800,
                              color: Colors.black, letterSpacing: 1.0)),
                    ]),
                  ),
                ),
              ),
            if (hasRelatedShow)
              _ContentBlock(
                label: 'ZUGEH\u00d6RIGE SHOW',
                child: GestureDetector(
                  onTap: () => context.push('${AppRoutes.showOverview}/${event.trashRelatedShowId}'),
                  child: Row(children: [
                    const Icon(Icons.tv_rounded, color: Colors.white38, size: 18),
                    const SizedBox(width: 12),
                    Text('Show anzeigen', style: GoogleFonts.dmSans(fontSize: 13, color: Colors.white70)),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
                  ]),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final Color accentColor;
  final String badgeLabel;
  final String title;
  final String? imageUrl;
  final String timeFormatted;

  const _HeroHeader({
    required this.accentColor,
    required this.badgeLabel,
    required this.title,
    required this.timeFormatted,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 260,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(bottom: BorderSide(color: accentColor, width: 2)),
      ),
      child: Stack(
        children: [
          // if (imageUrl != null)
          //   Positioned.fill(
          //     child: Opacity(
          //       opacity: 0.22,
          //       child: Image.network(imageUrl!, fit: BoxFit.cover,
          //           errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          //     ),
          //   )
          // else
          //   Positioned.fill(
          //     child: Center(
          //       child: Text('🎉', style: TextStyle(fontSize: 64,
          //           color: accentColor.withOpacity(0.18))),
          //     ),
          //   ),
          
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 4,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
              onPressed: () => context.pop(),
            ),
          ),
          Positioned(
            bottom: 24, left: 20, right: 20,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                color: accentColor,
                child: Text(badgeLabel,
                    style: GoogleFonts.montserrat(color: Colors.black, fontSize: 11,
                        fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              ),
              const SizedBox(height: 8),
              Text(title,
                  style: GoogleFonts.montserrat(color: Colors.white, fontSize: 26,
                      fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.1),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Text(timeFormatted,
                  style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ContentBlock extends StatelessWidget {
  final String label;
  final Widget child;
  const _ContentBlock({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        color: Colors.black,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 10,
                  fontWeight: FontWeight.w700, letterSpacing: 1.4)),
          const SizedBox(height: 10),
          child,
        ]),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool highlight;
  const _DetailRow({required this.icon, required this.text, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: highlight ? const Color(0xFFFFD700) : Colors.white38),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: GoogleFonts.dmSans(fontSize: 13,
                  color: highlight ? const Color(0xFFFFD700) : Colors.white70,
                  fontWeight: highlight ? FontWeight.w700 : FontWeight.w400)),
        ),
      ],
    );
  }
}
