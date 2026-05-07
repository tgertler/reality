import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/widgets/loading/app_skeleton.dart';
import 'package:frontend/core/widgets/last_releases_section_widget.dart';
import 'package:frontend/core/widgets/livedot_widget.dart';
import 'package:frontend/core/widgets/todays_shows_widget.dart';
import 'package:frontend/core/widgets/upcoming_releases_section_widget.dart';
import 'package:frontend/core/widgets/release_window_home_section_widget.dart';
import 'package:frontend/features/calendar_management/domain/entities/resolved_calendar_event.dart';
import 'package:frontend/features/calendar_management/presentation/providers/calendar_events_provider.dart';
import 'package:frontend/features/show_management/show_discovery/domain/entities/show.dart';
import 'package:frontend/features/show_management/show_discovery/presentation/providers/show_overview_provider.dart';
import 'package:frontend/features/user_management/presentation/providers/user_provider.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/providers/streaming_filter_provider.dart';

final homeResolvedEventsProvider =
    FutureProvider<List<ResolvedCalendarEvent>>((ref) async {
  final useCase = ref.read(getResolvedCalendarEventsForDateProvider);
  return useCase.execute(DateTime.now());
});

final homeUpcomingReleaseWindowShowsProvider =
    FutureProvider<List<Show>>((ref) async {
  final repository = ref.read(showRepositoryProvider);
  final shows = await repository.search('');
  return selectUpcomingReleaseWindowShows(shows);
});

class HomeStreamingContentWidget extends ConsumerStatefulWidget {
  const HomeStreamingContentWidget({super.key});

  @override
  _HomeStreamingContentWidgetState createState() =>
      _HomeStreamingContentWidgetState();
}

class _HomeStreamingContentWidgetState
    extends ConsumerState<HomeStreamingContentWidget> {
  // ZWEI separate PageController!
  final PageController _lastReleasesPageController = PageController(
    viewportFraction: 0.56,
  );

  final PageController _nextReleasesPageController = PageController(
    viewportFraction: 0.56,
  );

  int _selectedSection = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeEventsNotifierProvider.notifier).loadHomeData();
    });
  }

  @override
  void dispose() {
    _lastReleasesPageController.dispose();
    _nextReleasesPageController.dispose(); // Beide disposen!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userNotifierProvider);
    ref.listen<UserState>(userNotifierProvider, (previous, next) {
      final nextUserId = next.user?.id;
      final prevUserId = previous?.user?.id;
      if (nextUserId != null && nextUserId != prevUserId) {
        ref
            .read(streamingServiceFilterProvider.notifier)
            .loadForUser(nextUserId);
      }
    });
    final currentUserId = userState.user?.id;
    if (currentUserId != null) {
      ref
          .read(streamingServiceFilterProvider.notifier)
          .loadForUser(currentUserId);
    }

    final showsReleasingTodayState = ref.watch(homeEventsNotifierProvider);
    final nextThreePremieresState = showsReleasingTodayState.nextPremieres;
    final lastThreeReleasesState = showsReleasingTodayState.lastPremieres;

    final streamingFilter = ref.watch(streamingServiceFilterProvider);
    final todayEvents = streamingFilter.isEmpty
        ? showsReleasingTodayState.events
        : showsReleasingTodayState.events
            .where((e) => passesStreamingFilter(
                e.season.streamingOption, streamingFilter))
            .toList();
    final lastReleases = streamingFilter.isEmpty
        ? lastThreeReleasesState
        : lastThreeReleasesState
            .where((e) => passesStreamingFilter(
                e.season.streamingOption, streamingFilter))
            .toList();
    final nextPremieres = streamingFilter.isEmpty
        ? nextThreePremieresState
        : nextThreePremieresState
            .where((e) => passesStreamingFilter(
                e.season.streamingOption, streamingFilter))
            .toList();
    final resolvedEventsAsync = ref.watch(homeResolvedEventsProvider);
    final releaseWindowShowsAsync =
        ref.watch(homeUpcomingReleaseWindowShowsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Streaming-filter disclaimer (shown at top of home content)
          if (streamingFilter.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: AppColors.pop.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt_rounded,
                      color: AppColors.pop, size: 13),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Streaming-Filter aktiv: ${streamingFilter.join(' & ')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.pop,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (showsReleasingTodayState.isLoading &&
              showsReleasingTodayState.events.isEmpty &&
              showsReleasingTodayState.lastPremieres.isEmpty &&
              showsReleasingTodayState.nextPremieres.isEmpty)
            const _HomeStreamingSkeleton()
          else ...[
// HEUTE - BLOCK
            Container(
              margin: const EdgeInsets.only(top: 16.0, bottom: 12.0),
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 250),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.pop,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '📅 HEUTE',
                              style: GoogleFonts.montserrat(
                                color: Colors.black,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const LiveRecordingDot(),
                        ],
                      ),
                      const SizedBox(height: 12),
                      showsReleasingTodayState.errorMessage.isNotEmpty
                          ? Center(
                              child: Text(
                              'Error: ${showsReleasingTodayState.errorMessage}',
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 14),
                            ))
                          : todayEvents.isEmpty
                              ? Text(
                                  'Heute kommt leider nichts neues raus!',
                                  style: const TextStyle(
                                      color: Color.fromARGB(137, 0, 0, 0),
                                      fontSize: 14),
                                )
                              : TodayShowsWidget(
                                  events: todayEvents,
                                ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 0.0, bottom: 24.0),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SectionTabChip(
                        label: '⏮️ ZULETZT',
                        active: _selectedSection == 0,
                        onTap: () => setState(() => _selectedSection = 0),
                      ),
                      const SizedBox(width: 6),
                      _SectionTabChip(
                        label: '🔜 BALD',
                        active: _selectedSection == 1,
                        onTap: () => setState(() => _selectedSection = 1),
                      ),
                      const SizedBox(width: 6),
                      _SectionTabChip(
                        label: '🤔 TEASER',
                        active: _selectedSection == 2,
                        onTap: () => setState(() => _selectedSection = 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: KeyedSubtree(
                      key: ValueKey(_selectedSection),
                      child: _selectedSection == 0
                          ? LastReleasesSectionWidget(
                              events: lastReleases,
                              controller: _lastReleasesPageController,
                              showHeader: false,
                            )
                          : _selectedSection == 1
                              ? UpcomingPremieresSectionWidget(
                                  events: nextPremieres,
                                  controller: _nextReleasesPageController,
                                  showHeader: false,
                                )
                              : releaseWindowShowsAsync.when(
                                  loading: () => const SizedBox(
                                    height: 165,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.pop,
                                      ),
                                    ),
                                  ),
                                  error: (_, __) => const SizedBox.shrink(),
                                  data: (shows) => shows.isEmpty
                                      ? const Padding(
                                          padding: EdgeInsets.only(top: 8),
                                          child: Text(
                                            'Keine Teaser-Shows verfügbar',
                                            style: TextStyle(
                                                color: Colors.black54,
                                                fontSize: 13),
                                          ),
                                        )
                                      : ReleaseWindowHomeSectionWidget(
                                          shows: shows,
                                          showHeader: false,
                                        ),
                                ),
                    ),
                  ),
                ],
              ),
            ),
            resolvedEventsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (events) {
                final creatorEvents = events
                    .where((event) => event.isCreatorEvent)
                    .take(2)
                    .toList();
                final communityEvents = events
                    .where((event) => event.isTrashEvent)
                    .take(2)
                    .toList();

                if (creatorEvents.isEmpty && communityEvents.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 24.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aus der Community',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (creatorEvents.isNotEmpty)
                          _HomeSecondaryEventsCard(
                            title: 'Creator',
                            icon: Icons.videocam_rounded,
                            accentColor: const Color(0xFF4DB6FF),
                            events: creatorEvents,
                            labelBuilder: (event) =>
                                event.creatorEventTitle ??
                                event.creatorName ??
                                'Creator Event',
                            subLabelBuilder: (event) => event.creatorName,
                            onTap: (event) {
                              context.push(AppRoutes.creatorEventDetail,
                                  extra: event);
                            },
                          ),
                        if (creatorEvents.isNotEmpty &&
                            communityEvents.isNotEmpty)
                          const SizedBox(height: 8),
                        if (communityEvents.isNotEmpty)
                          _HomeSecondaryEventsCard(
                            title: 'Community',
                            icon: Icons.celebration_rounded,
                            accentColor: const Color(0xFFFFD700),
                            events: communityEvents,
                            labelBuilder: (event) =>
                                event.trashEventTitle ?? 'Community Event',
                            subLabelBuilder: (event) =>
                                event.trashEventLocation,
                            onTap: (event) {
                              context.push(AppRoutes.trashEventDetail,
                                  extra: event);
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ]
        ],
      ),
    );
  }
}

class _SectionTabChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SectionTabChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: active ? Colors.black : Colors.black12,
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: active ? Colors.white : const Color(0xFF1E1E1E),
          ),
        ),
      ),
    );
  }
}

class _HomeSecondaryEventsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<ResolvedCalendarEvent> events;
  final String Function(ResolvedCalendarEvent event) labelBuilder;
  final String? Function(ResolvedCalendarEvent event) subLabelBuilder;
  final void Function(ResolvedCalendarEvent event) onTap;

  const _HomeSecondaryEventsCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.events,
    required this.labelBuilder,
    required this.subLabelBuilder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            color: accentColor.withValues(alpha: 0.15),
            child: Row(
              children: [
                Icon(icon, color: accentColor, size: 14),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          ...events.asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            final subLabel = subLabelBuilder(event);

            return InkWell(
              onTap: () => onTap(event),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  border: Border(
                    top: index == 0
                        ? BorderSide.none
                        : const BorderSide(color: Colors.black12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labelBuilder(event),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    if (subLabel != null && subLabel.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _HomeStreamingSkeleton extends StatelessWidget {
  const _HomeStreamingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _HomeTodaySkeleton(),
        _HorizontalReleaseSkeleton(),
        _HorizontalReleaseSkeleton(isLarge: true),
      ],
    );
  }
}

class _HomeTodaySkeleton extends StatelessWidget {
  const _HomeTodaySkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16.0, bottom: 12.0),
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 250),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                AppSkeletonBox(
                    width: 68,
                    height: 24,
                    borderRadius: BorderRadius.all(Radius.circular(4))),
                SizedBox(width: 8),
                AppSkeletonCircle(size: 12),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(
              4,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  color: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  child: const Row(
                    children: [
                      AppSkeletonBox(width: 20, height: 12),
                      SizedBox(width: 10),
                      Expanded(child: AppSkeletonBox(height: 14)),
                      SizedBox(width: 8),
                      AppSkeletonBox(
                          width: 44,
                          height: 18,
                          borderRadius: BorderRadius.all(Radius.circular(4))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalReleaseSkeleton extends StatelessWidget {
  final bool isLarge;

  const _HorizontalReleaseSkeleton({this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 0.0, bottom: isLarge ? 24.0 : 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                AppSkeletonBox(
                    width: 64,
                    height: 22,
                    borderRadius: BorderRadius.all(Radius.circular(4))),
                SizedBox(width: 10),
                AppSkeletonBox(width: 160, height: 16),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 135,
              child: Row(
                children: const [
                  Expanded(child: _ReleaseCardSkeleton()),
                  SizedBox(width: 10),
                  Expanded(child: _ReleaseCardSkeleton()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReleaseCardSkeleton extends StatelessWidget {
  const _ReleaseCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            AppSkeletonLines(lines: 2, height: 13, widths: [1, 0.7]),
            AppSkeletonBox(width: 92, height: 12),
            Row(
              children: [
                AppSkeletonBox(
                    width: 36,
                    height: 18,
                    borderRadius: BorderRadius.all(Radius.circular(4))),
                Spacer(),
                AppSkeletonCircle(size: 18),
                SizedBox(width: 8),
                AppSkeletonBox(width: 42, height: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
