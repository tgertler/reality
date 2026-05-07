import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/core/utils/streaming_service_logo.dart';
import 'package:frontend/features/feed_management/data/models/feed_item.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/feed_card_helpers.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class TodayShowsBlockFeedCard extends StatefulWidget {
  final FeedItem item;

  const TodayShowsBlockFeedCard({super.key, required this.item});

  @override
  State<TodayShowsBlockFeedCard> createState() =>
      _TodayShowsBlockFeedCardState();
}

class _TodayShowsBlockFeedCardState extends State<TodayShowsBlockFeedCard> {
  int _pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final items = parseFeedItems(
      widget.item.data['items'] ??
          widget.item.data['today_events'] ??
          widget.item.data['events'] ??
          widget.item.data,
    );

    final showCount = items.length;
    final totalPages = showCount == 0 ? 1 : ((showCount - 1) ~/ 4) + 1;

    if (_pageIndex >= totalPages) {
      _pageIndex = totalPages - 1;
    }

    final start = _pageIndex * 4;
    final end = (start + 4) > showCount ? showCount : (start + 4);
    final pageItems =
        showCount == 0 ? const <Map<String, dynamic>>[] : items.sublist(start, end);

    return Padding(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              //   decoration: const BoxDecoration(
              //     color: AppColors.pop,
              //     border: Border.fromBorderSide(
              //       BorderSide(color: Colors.black, width: 2),
              //     ),
              //   ),
              //   child: Text(
              //     'IM FEED',
              //     style: GoogleFonts.dmSans(
              //       color: Colors.black,
              //       fontSize: 11,
              //       fontWeight: FontWeight.w900,
              //       letterSpacing: 0.8,
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 14),
              Text(
                'HEUTE GEHTS',
                style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontSize: 44,
                  height: 0.95,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'WEITER...',
                style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontSize: 44,
                  height: 0.95,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: 116,
                height: 8,
                color: AppColors.pop,
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: pageItems.isEmpty
                        ? const _EmptyTodayShowsCard()
                        : GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: pageItems.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.32,
                            ),
                            itemBuilder: (context, index) {
                              final entry = pageItems[index];
                              return _TodayShowTile(
                                title: resolvePreferredShowTitle(
                                  entry,
                                  fallback: 'Show',
                                ),
                                subtitle: _todayShowSubtitle(start + index),
                                streamingService:
                                    _resolveStreamingService(entry),
                                onTap: () => _openEntry(context, entry),
                              );
                            },
                          ),
                  ),
                  if (showCount > 4) ...[
                    const SizedBox(width: 10),
                    Column(
                      children: [
                        const SizedBox(height: 2),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _pageIndex = (_pageIndex + 1) % totalPages;
                            });
                          },
                          child: Container(
                            width: 44,
                            height: 44,
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
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.black,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_pageIndex + 1}/$totalPages',
                          style: GoogleFonts.dmSans(
                            color: Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const Spacer(),
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

  String _todayShowSubtitle(int index) {
    const phrases = [
      'Jetzt streamen',
      'Heute neu',
      'Ab heute verfugbar',
      'Direkt anschauen',
      'Heute frisch',
    ];
    return phrases[index % phrases.length];
  }

  void _openEntry(BuildContext context, Map<String, dynamic> entry) {
    final showEventId = _firstNonEmptyString([
      entry['show_event_id'],
      entry['showEventId'],
      entry['show_event'] is Map ? (entry['show_event'] as Map)['id'] : null,
      entry['show_event'] is Map
          ? (entry['show_event'] as Map)['show_event_id']
          : null,
      entry['event'] is Map ? (entry['event'] as Map)['show_event_id'] : null,
      entry['event_id'],
    ]);

    final showId = _firstNonEmptyString([
      entry['show_id'],
      entry['showId'],
      entry['show'] is Map ? (entry['show'] as Map)['id'] : null,
      entry['show'] is Map ? (entry['show'] as Map)['show_id'] : null,
      entry['show_event'] is Map
          ? (entry['show_event'] as Map)['show_id']
          : null,
      entry['event'] is Map ? (entry['event'] as Map)['show_id'] : null,
      entry['id'],
    ]);

    if (showId != null && showId.isNotEmpty) {
      context.push('${AppRoutes.showOverview}/$showId');
      return;
    }
    if (showEventId != null && showEventId.isNotEmpty) {
      context.go(AppRoutes.calendar);
      return;
    }
    context.go(AppRoutes.calendar);
  }

  String? _firstNonEmptyString(List<dynamic> candidates) {
    for (final candidate in candidates) {
      final value = candidate?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}

class _TodayShowTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String streamingService;
  final VoidCallback onTap;

  const _TodayShowTile({
    required this.title,
    required this.subtitle,
    required this.streamingService,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F0E8),
          border: Border.fromBorderSide(
            BorderSide(color: Colors.black, width: 2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              offset: Offset(4, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  color: Colors.black,
                  fontSize: 18,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      color: Colors.black.withValues(alpha: 0.65),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (streamingService.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 42,
                    height: 14,
                    child: SvgPicture.asset(
                      getStreamingServiceLogo(streamingService),
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTodayShowsCard extends StatelessWidget {
  const _EmptyTodayShowsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F0E8),
        border: Border.fromBorderSide(
          BorderSide(color: Colors.black, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Heute ist nichts geplant',
          style: GoogleFonts.dmSans(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
