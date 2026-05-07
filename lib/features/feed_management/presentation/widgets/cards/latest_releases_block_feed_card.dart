import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/core/utils/streaming_service_logo.dart';
import 'package:frontend/features/feed_management/data/models/feed_item.dart';
import 'feed_card_helpers.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _kDotSize = 10.0;
const _kLineWidth = 2.0;
const _kTimelineColWidth = 36.0;
const _kTileMinHeight = 92.0;
const _kTileGap = 12.0;
const _kDotTop = 41.0;

class LatestReleasesBlockFeedCard extends StatelessWidget {
  final FeedItem item;

  const LatestReleasesBlockFeedCard({super.key, required this.item});

  String _relativeAgo(String? raw) {
    if (raw == null || raw.isEmpty) return 'Kürzlich';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return 'Kürzlich';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Heute';
    if (diff.inDays == 1) return 'Gestern';
    if (diff.inDays < 7) return 'vor ${diff.inDays} Tagen';
    if (diff.inDays < 14) return 'letzte Woche';
    return 'vor ${(diff.inDays / 7).floor()} Wochen';
  }

  @override
  Widget build(BuildContext context) {
    final items = parseFeedItems(
      item.data['items'] ??
          item.data['latest_releases'] ??
          item.data['events'] ??
          item.data,
    );
    final preview = items.take(4).toList();

    return Padding(
      padding: EdgeInsets.zero,
      child: Container(
        //height: MediaQuery.of(context).size.height * 0.78,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 18, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: const BoxDecoration(
                    // border: Border(
                    //   left: BorderSide(color: AppColors.pop, width: 5),
                    // ),
                    ),
                padding: const EdgeInsets.only(left: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.pop,
                        border: Border.fromBorderSide(
                          BorderSide(color: Colors.black, width: 2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'NEUERSCHEINUNGEN',
                        style: GoogleFonts.dmSans(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'DAS HAST DU',
                      style: GoogleFonts.montserrat(
                        color: Colors.black,
                        fontSize: 44,
                        height: 0.95,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                      ),
                    ),
                    Text(
                      'VERPASST!',
                      style: GoogleFonts.montserrat(
                        color: AppColors.pop,
                        fontSize: 44,
                        height: 0.95,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: preview.isEmpty
                    ? const _EmptyState()
                    : Column(
                        children: [
                          for (int i = 0; i < preview.length; i++)
                            _TimelineRow(
                              title: resolvePreferredShowTitle(
                                preview[i],
                                fallback: 'Show',
                              ),
                              timeLabel: _relativeAgo(
                                preview[i]['datetime']?.toString(),
                              ),
                              streamingService:
                                  _resolveStreamingService(preview[i]),
                              isFirst: i == 0,
                              isLast: i == preview.length - 1,
                              onTap: () => _openEntry(context, preview[i]),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => context.go(AppRoutes.calendar),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: AppColors.pop,
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.black, width: 2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(3, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Zum Kalender',
                        style: GoogleFonts.dmSans(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _resolveStreamingService(Map<String, dynamic> entry) {
    final value = (entry['streaming_option'] ??
            entry['streamingOption'] ??
            entry['streaming_service'] ??
            entry['streamingService'])
        ?.toString()
        .trim();
    return value ?? '';
  }

  void _openEntry(BuildContext context, Map<String, dynamic> entry) {
    final showEventId =
        (entry['show_event_id'] ?? entry['showEventId'] ?? entry['event_id'])
            ?.toString()
            .trim();
    final showId = (entry['show_id'] ??
            entry['showId'] ??
            (entry['show'] is Map ? (entry['show'] as Map)['id'] : null) ??
            (entry['show_event'] is Map
                ? (entry['show_event'] as Map)['show_id']
                : null) ??
            entry['id'])
        ?.toString()
        .trim();

    if (showId != null && showId.isNotEmpty) {
      context.push('${AppRoutes.showOverview}/$showId');
      return;
    }
    if (showEventId != null && showEventId.isNotEmpty) {
      context.go(AppRoutes.calendar);
    }
  }
}

class _TimelineRow extends StatelessWidget {
  final String title;
  final String timeLabel;
  final String streamingService;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _TimelineRow({
    required this.title,
    required this.timeLabel,
    required this.streamingService,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isFirst ? AppColors.pop : Colors.black26;

    final rowHeight = isLast ? _kTileMinHeight : _kTileMinHeight + _kTileGap;

    return SizedBox(
      height: rowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Timeline indicator ──────────────────────────────────────────
          SizedBox(
            width: _kTimelineColWidth,
            child: Stack(
              children: [
                if (!isFirst)
                  Positioned(
                    top: 0,
                    bottom: rowHeight - (_kDotTop + (_kDotSize / 2)),
                    left: _kTimelineColWidth / 2 - _kLineWidth / 2,
                    child: Container(
                      width: _kLineWidth,
                      color: Colors.black26,
                    ),
                  ),
                if (!isLast)
                  Positioned(
                    top: _kDotTop + (_kDotSize / 2),
                    bottom: 0,
                    left: _kTimelineColWidth / 2 - _kLineWidth / 2,
                    child: Container(
                      width: _kLineWidth,
                      color: Colors.black26,
                    ),
                  ),
                Positioned(
                  top: _kDotTop,
                  left: _kTimelineColWidth / 2 - _kDotSize / 2,
                  child: Container(
                    width: _kDotSize,
                    height: _kDotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFirst ? AppColors.pop : dotColor,
                      border: Border.all(color: dotColor, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // ── Tile ─────────────────────────────────────────────────────────
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: _kTileMinHeight,
                width: double.infinity,
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F1F1),
                      border: Border.all(
                        color: Colors.black,
                        width: isFirst ? 2 : 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(3, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeLabel.toUpperCase(),
                          style: GoogleFonts.dmSans(
                            color: isFirst
                                ? AppColors.pop.withValues(alpha: 0.9)
                                : Colors.black45,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            color: Colors.black,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.18,
                          ),
                        ),
                        if (streamingService.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 48,
                            height: 14,
                            child: SvgPicture.asset(
                              getStreamingServiceLogo(streamingService),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Nichts verpasst! 🎉',
        style: GoogleFonts.dmSans(
          color: Colors.black45,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
