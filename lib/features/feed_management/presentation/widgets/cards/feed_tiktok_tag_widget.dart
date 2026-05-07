import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:frontend/features/show_management/show_discovery/presentation/providers/show_social_provider.dart';

/// Compact one-line TikTok tag pill for feed cards.
///
/// Shows nothing (SizedBox.shrink) if:
/// - [showId] is empty
/// - no tags are available for the show
/// - tags fail to load
///
/// [prefix] appears before the hashtag, [suffix] after it.
/// Example: prefix="Trending auf TikTok: " → "Trending auf TikTok: #LoveIslandDE"
/// Example: suffix=" findet diese Show spannend" → "#RealityTok findet diese Show spannend"
class FeedCardTikTokTag extends ConsumerWidget {
  final String showId;
  final String prefix;
  final String suffix;

  /// true → assumes dark card background (white text, soft white chip)
  /// false → assumes light card background (dark text, soft black chip)
  final bool isDark;

  const FeedCardTikTokTag({
    super.key,
    required this.showId,
    this.prefix = '',
    this.suffix = '',
    this.isDark = true,
  });

  Future<void> _openTikTok(String tag) async {
    final deepLink = Uri.parse(
        'snssdk1233://challenge/detail/?hashtag=${Uri.encodeComponent(tag)}');
    final webUrl =
        Uri.parse('https://www.tiktok.com/tag/${Uri.encodeComponent(tag)}');
    if (!await launchUrl(deepLink,
        mode: LaunchMode.externalNonBrowserApplication)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (showId.isEmpty) return const SizedBox.shrink();

    final tagsAsync = ref.watch(showSocialTagsProvider(showId));

    return tagsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (tags) {
        if (tags.isEmpty) return const SizedBox.shrink();

        final primary = tags.firstWhere(
          (t) => t.isPrimary,
          orElse: () => tags.first,
        );
        final tagText = primary.displayTag.isNotEmpty
            ? primary.displayTag
            : '#${primary.tag}';

        final textColor =
            isDark ? Colors.white.withValues(alpha: 0.75) : Colors.black54;
        final chipBg = isDark
            ? Colors.white.withValues(alpha: 0.10)
            : Colors.black.withValues(alpha: 0.06);

        return GestureDetector(
          onTap: () => _openTikTok(primary.tag),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: chipBg,
              //borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    '$prefix$tagText',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
