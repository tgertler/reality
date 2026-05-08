import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/features/feed_management/data/models/feed_item.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class TrashEventsBlockFeedCard extends StatelessWidget {
  final FeedItem item;

  const TrashEventsBlockFeedCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final data = item.data;
    final events = _parseEvents(data['events']);

    return Container(
      height: MediaQuery.of(context).size.height * 0.84,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TRASH',
                        style: GoogleFonts.montserrat(
                          color: Colors.black,
                          fontSize: 36,
                          height: 0.95,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.4,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 14),
                        child: Text(
                          'EVENT GUIDE',
                          style: GoogleFonts.montserrat(
                            color: AppColors.pop,
                            fontSize: 28,
                            height: 0.95,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Bevorstehende Events aus der Reality-Welt',
              style: GoogleFonts.dmSans(
                color: Colors.black45,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            if (events.isEmpty)
              _emptyState()
            else
              Expanded(
                child: Column(
                  children: events.asMap().entries.map((entry) {
                    final idx = entry.key;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: idx < events.length - 1 ? 8 : 0),
                        child: _EventTile(event: entry.value),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Expanded(
      child: Center(
        child: Text(
          'Keine kommenden Events',
          style: GoogleFonts.dmSans(color: Colors.black45, fontSize: 14),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _parseEvents(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }
}

class _EventTile extends StatelessWidget {
  final Map<String, dynamic> event;

  const _EventTile({required this.event});

  String get title => event['title'] as String? ?? '';
  String get description => event['description'] as String? ?? '';
  String get location => event['location'] as String? ?? '';
  String get organizer => event['organizer'] as String? ?? '';
  String get externalUrl => event['external_url'] as String? ?? '';
  String get relatedShowTitle => event['related_show_title'] as String? ?? '';
  String get startDatetime => event['start_datetime'] as String? ?? '';

  DateTime? get parsedDate {
    try {
      return DateTime.parse(startDatetime).toLocal();
    } catch (_) {
      return null;
    }
  }

  String get formattedDate {
    final dt = parsedDate;
    if (dt == null) return '';
    return DateFormat('EEE, d. MMM', 'de').format(dt);
  }

  String get formattedTime {
    final dt = parsedDate;
    if (dt == null) return '';
    return DateFormat('HH:mm', 'de').format(dt);
  }

  Future<void> _open() async {
    final uri = Uri.tryParse(externalUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Date chip + show tag row
          Row(
            children: [
              if (formattedDate.isNotEmpty || formattedTime.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.pop,
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formattedDate.toUpperCase(),
                        style: GoogleFonts.dmSans(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (formattedTime.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '$formattedTime UHR',
                          style: GoogleFonts.dmSans(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              if (relatedShowTitle.isNotEmpty)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      color: Colors.black,
                      child: Text(
                        relatedShowTitle.toUpperCase(),
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Title
          Text(
            title,
            style: GoogleFonts.montserrat(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Description (optional)
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: GoogleFonts.dmSans(
                color: Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const Spacer(),
          // Meta row: location / organizer / price
          Row(
            children: [
              if (location.isNotEmpty)
                Expanded(
                  child: Text(
                    location,
                    style: GoogleFonts.dmSans(
                      color: Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (externalUrl.isNotEmpty) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _open,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      boxShadow: const [
                        BoxShadow(
                            color: AppColors.pop,
                            offset: Offset(2, 2),
                            blurRadius: 0),
                      ],
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'MEHR →',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
