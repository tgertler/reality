import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/features/feed_management/data/models/feed_item.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ShowTiktokHashtagsBlockFeedCard extends StatelessWidget {
  final FeedItem item;

  const ShowTiktokHashtagsBlockFeedCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final data = item.data;
    final shows = _parseShows(data['shows']);

    return Container(
      height: MediaQuery.of(context).size.height * 0.84,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HASHTAGS',
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
                          'FÜR TIKTOK',
                          style: GoogleFonts.montserrat(
                            color: AppColors.pop,
                            fontSize: 36,
                            height: 0.95,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // TikTok logo badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    boxShadow: const [
                      BoxShadow(
                          color: AppColors.pop, offset: Offset(2, 2), blurRadius: 0),
                    ],
                  ),
                  child: Text(
                    'TikTok',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tippe auf einen Hashtag → direkt zu TikTok',
              style: GoogleFonts.dmSans(
                color: Colors.black45,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            if (shows.isEmpty)
              _emptyState()
            else
              Expanded(
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: shows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _ShowHashtagBlock(show: shows[i]),
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
          'Noch keine Hashtags hinterlegt',
          style: GoogleFonts.dmSans(color: Colors.black45, fontSize: 14),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _parseShows(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }
}

class _ShowHashtagBlock extends StatelessWidget {
  final Map<String, dynamic> show;

  const _ShowHashtagBlock({required this.show});

  String get showTitle => show['show_title'] as String? ?? '';
  bool get isCurrent => show['is_current'] as bool? ?? false;

  List<Map<String, dynamic>> get tags {
    final raw = show['tags'];
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().toList();
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
        children: [
          // Show title row
          Row(
            children: [
              Expanded(
                child: Text(
                  showTitle.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isCurrent) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: AppColors.pop,
                  child: Text(
                    'AKTUELL',
                    style: GoogleFonts.dmSans(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          // Hashtag chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags.map((t) => _HashtagChip(tag: t)).toList(),
          ),
        ],
      ),
    );
  }
}

class _HashtagChip extends StatelessWidget {
  final Map<String, dynamic> tag;

  const _HashtagChip({required this.tag});

  String get displayTag => tag['display_tag'] as String? ?? '';
  String get rawTag => tag['tag'] as String? ?? '';
  bool get isPrimary => tag['is_primary'] as bool? ?? false;

  Future<void> _openTikTok() async {
    // Strip leading # for the URL
    final clean = rawTag.startsWith('#') ? rawTag.substring(1) : rawTag;
    // Try app deep link first, fall back to web
    final appUri = Uri.tryParse('snssdk1233://challenge/detail?title=$clean');
    final webUri = Uri.parse('https://www.tiktok.com/tag/$clean');
    if (appUri != null && await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openTikTok,
      child: Container(
        decoration: BoxDecoration(
          color: isPrimary ? Colors.black : Colors.white,
          border: Border.all(color: Colors.black, width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: AppColors.pop, offset: Offset(1, 1), blurRadius: 0),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          displayTag,
          style: GoogleFonts.dmSans(
            color: isPrimary ? Colors.white : Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
