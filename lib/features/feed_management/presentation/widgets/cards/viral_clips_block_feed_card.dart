import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/features/feed_management/data/models/feed_item.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ViralClipsBlockFeedCard extends StatelessWidget {
  final FeedItem item;

  const ViralClipsBlockFeedCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final data = item.data;
    final videos = _parseVideos(data['videos']);

    return Container(
      height: MediaQuery.of(context).size.height * 0.80,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GERADE',
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
                'VIRAL',
                style: GoogleFonts.montserrat(
                  color: AppColors.pop,
                  fontSize: 36,
                  height: 0.95,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.4,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'TikToks & Reels aus der Reality-Welt',
              style: GoogleFonts.dmSans(
                color: Colors.black45,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            if (videos.isEmpty)
              _emptyState()
            else
              Expanded(
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: videos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _VideoTile(video: videos[i]),
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
          'Keine Clips verfügbar',
          style: GoogleFonts.dmSans(color: Colors.black45, fontSize: 14),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _parseVideos(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().toList();
  }
}

class _VideoTile extends StatelessWidget {
  final Map<String, dynamic> video;

  const _VideoTile({required this.video});

  String get showTitle => video['show_title'] as String? ?? '';
  String get platform => (video['platform'] as String? ?? 'tiktok').toUpperCase();
  String get videoUrl => video['video_url'] as String? ?? '';

  Future<void> _open() async {
    final uri = Uri.tryParse(videoUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Platform badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.black, width: 1),
            ),
            child: Text(
              platform,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              showTitle,
              style: GoogleFonts.montserrat(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _open,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.pop,
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                'ÖFFNEN →',
                style: GoogleFonts.dmSans(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
