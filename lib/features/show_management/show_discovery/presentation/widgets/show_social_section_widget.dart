import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/show_social_tag.dart';
import '../../domain/entities/show_social_video.dart';
import '../providers/show_social_provider.dart';

class ShowSocialSection extends ConsumerWidget {
  final String showId;
  final Color accentColor;

  const ShowSocialSection({
    super.key,
    required this.showId,
    this.accentColor = AppColors.pop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(showSocialTagsProvider(showId));
    final videosAsync = ref.watch(showSocialVideosProvider(showId));

    return tagsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (tags) {
        if (tags.isEmpty) return const SizedBox.shrink();

        // Keep max 3 tags, primary first
        final displayTags = tags.take(3).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      //color: Colors.black,
                      child: Text(
                        'TRENDING AUF TIKTOK',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // TikTok music note icon substitute
                    Text('♪', style: TextStyle(color: accentColor, fontSize: 14)),
                  ],
                ),
              ),

              // ── Tag Chips ─────────────────────────────────────────────────
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: displayTags
                  .map((tag) => _TikTokTagChip(tag: tag, accentColor: accentColor))
                    .toList(),
              ),

              // ── Videos (optional) ─────────────────────────────────────────
              videosAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (videos) {
                  if (videos.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _TikTokVideosSection(
                      videos: videos,
                      accentColor: accentColor,
                    ),
                  );
                },
              ),

              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }
}

// ─── Single tag chip ──────────────────────────────────────────────────────────

class _TikTokTagChip extends StatelessWidget {
  final ShowSocialTag tag;
  final Color accentColor;

  const _TikTokTagChip({required this.tag, required this.accentColor});

  Future<void> _openTikTok() async {
    // Try deep link first, fall back to browser
    final deepLink = Uri.parse('snssdk1233://challenge/detail/?hashtag=${tag.tag}');
    final webUrl = Uri.parse('https://www.tiktok.com/tag/${tag.tag}');

    if (!await launchUrl(deepLink, mode: LaunchMode.externalNonBrowserApplication)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPrimary = tag.isPrimary;

    return GestureDetector(
      onTap: _openTikTok,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isPrimary ? accentColor : Colors.black,
          border: Border.all(
            color: isPrimary ? accentColor : Colors.white24,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag.displayTag,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isPrimary ? const Color(0xFF1E1E1E) : Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.open_in_new,
              size: 11,
              color: isPrimary ? const Color(0xFF1E1E1E) : Colors.white38,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Videos section ───────────────────────────────────────────────────────────

class _TikTokVideosSection extends StatelessWidget {
  final List<ShowSocialVideo> videos;
  final Color accentColor;

  const _TikTokVideosSection({
    required this.videos,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Beliebte TikTok-Clips',
          style: GoogleFonts.montserrat(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        ...videos.map((v) => _TikTokVideoRow(video: v, accentColor: accentColor)),
      ],
    );
  }
}

class _TikTokVideoRow extends StatelessWidget {
  final ShowSocialVideo video;
  final Color accentColor;

  const _TikTokVideoRow({required this.video, required this.accentColor});

  Future<void> _open() async {
    final url = Uri.parse(video.videoUrl);
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _open,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: Colors.black,
        child: Row(
          children: [
            Container(
              width: 3,
              height: 36,
              color: accentColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TikTok-Clip ansehen',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    video.videoUrl,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: Colors.white24,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.play_circle_outline, color: accentColor, size: 24),
          ],
        ),
      ),
    );
  }
}
