import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/providers/trash_event_city_filter_provider.dart';
import 'package:frontend/features/calendar_management/presentation/providers/category_filter_provider.dart';
import 'package:frontend/features/calendar_management/presentation/providers/favorites_only_filter_provider.dart';
import 'package:frontend/core/providers/streaming_filter_provider.dart';
import 'package:frontend/features/calendar_management/domain/entities/resolved_calendar_event.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/calendar_creator_event_card_widget.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/calendar_resolved_show_event_card_widget.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/calendar_trash_event_card_widget.dart';
import 'package:frontend/features/favorites_management/presentation/providers/favorites_provider.dart';
import 'package:frontend/features/user_management/presentation/providers/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/calendar_events_provider.dart';
import '../providers/filter_active_provider.dart';
import '../providers/datepicker_provider.dart';
import '../providers/filter_overlay_provider.dart';
import '../utils/calendar_event_grouping.dart';
import '../utils/calendar_event_sorting.dart';

class CalendarBodyWidget extends ConsumerStatefulWidget {
  const CalendarBodyWidget({super.key});

  @override
  _CalendarBodyWidgetState createState() => _CalendarBodyWidgetState();
}

class _CalendarBodyWidgetState extends ConsumerState<CalendarBodyWidget> {
  final Map<String, bool> _sectionExpanded = {
    'shows': true,
    'creator': true,
    'community': true,
  };
  final ScrollController _eventsScrollController = ScrollController();
  bool _showTopScrollHint = false;
  bool _showBottomScrollHint = false;
  bool _hasRequestedFavoriteShows = false;

  @override
  void initState() {
    super.initState();
    _eventsScrollController.addListener(_updateScrollHints);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final datepickerState = ref.read(datepickerNotifierProvider);
      final notifier = ref.read(calendarEventsNotifierProvider.notifier);
      notifier.fetchResolvedEventsForDate(datepickerState.selectedDate);
      _updateScrollHints();
    });
  }

  @override
  void dispose() {
    _eventsScrollController
      ..removeListener(_updateScrollHints)
      ..dispose();
    super.dispose();
  }

  void _scheduleScrollHintUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateScrollHints();
    });
  }

  void _updateScrollHints() {
    if (!_eventsScrollController.hasClients) {
      if (_showTopScrollHint || _showBottomScrollHint) {
        setState(() {
          _showTopScrollHint = false;
          _showBottomScrollHint = false;
        });
      }
      return;
    }

    final position = _eventsScrollController.position;
    const epsilon = 1.0;
    final nextTop = position.pixels > epsilon;
    final nextBottom = position.maxScrollExtent - position.pixels > epsilon;

    if (nextTop != _showTopScrollHint || nextBottom != _showBottomScrollHint) {
      setState(() {
        _showTopScrollHint = nextTop;
        _showBottomScrollHint = nextBottom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final datepickerState = ref.watch(datepickerNotifierProvider);
    final state = ref.watch(calendarEventsNotifierProvider);
    final notifier = ref.read(calendarEventsNotifierProvider.notifier);
    final favoritesOnly = ref.watch(favoritesOnlyFilterProvider);
    final activeFiltersState = ref.watch(activeFiltersProvider);
    final selectedGenres = ref.watch(selectedGenreFiltersProvider);
    final favState = ref.watch(favoritesNotifierProvider);
    final userState = ref.watch(userNotifierProvider);
    _scheduleScrollHintUpdate();
    final selectedTrashCity = ref.watch(trashEventCityFilterProvider);

    final userId = userState.user?.id;
    if (userId != null && !_hasRequestedFavoriteShows && !favState.isLoading) {
      _hasRequestedFavoriteShows = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(favoritesNotifierProvider.notifier).fetchFavoriteShows(userId);
      });
    }

    // Load favorites when the toggle is switched on and they aren't loaded yet
    ref.listen<bool>(favoritesOnlyFilterProvider, (prev, next) {
      if (next && favState.favoriteShows.isEmpty) {
        final userId = userState.user?.id;
        if (userId != null) {
          ref
              .read(favoritesNotifierProvider.notifier)
              .fetchFavoriteShows(userId);
        }
      }
    });

    final favoriteShowIds = favState.favoriteShows.map((s) => s.showId).toSet();
    final activeShowIds =
      activeFiltersState.activeShows.map((show) => show.showId).toSet();
    final displayedResolvedEvents = favoritesOnly
        ? state.resolvedEvents
            .where((e) => favoriteShowIds.contains(e.relatedShowId))
            .toList()
        : state.resolvedEvents;

    final streamingFilter = ref.watch(streamingServiceFilterProvider);
    // Streaming filter applied to show-events only; creator/community events
    // are not bound to a streaming platform so they are always shown.
    final filteredShowEvents = displayedResolvedEvents.where((e) {
      if (!e.isShowEvent) {
        return false;
      }
      if (activeShowIds.isNotEmpty &&
          (e.relatedShowId == null || !activeShowIds.contains(e.relatedShowId))) {
        return false;
      }
      if (!passesStreamingFilter(e.showEventStreamingOption, streamingFilter)) {
        return false;
      }
      if (selectedGenres.isEmpty) {
        return true;
      }

      final rawCategory = (e.showEventGenre ?? '').trim().toLowerCase();
      if (rawCategory.isEmpty) {
        return false;
      }

      final categoryTokens = rawCategory
          .split(RegExp(r'[,/|]'))
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet();

      if (categoryTokens.isEmpty) {
        return false;
      }

      return selectedGenres.any(
        (genre) => categoryTokens.contains(genre.trim().toLowerCase()),
      );
    }).toList();
    filteredShowEvents.sort(
      (a, b) => compareCalendarShowEvents(a, b, favoriteShowIds),
    );

    final filteredTrashEvents = displayedResolvedEvents
        .where((e) => e.isTrashEvent)
      .where(
        (e) => activeShowIds.isEmpty ||
          (e.relatedShowId != null && activeShowIds.contains(e.relatedShowId)),
      )
        .where((e) =>
            passesTrashCityFilter(e.trashEventLocation, selectedTrashCity))
        .toList();

    final filteredCreatorEvents = displayedResolvedEvents
      .where((e) => e.isCreatorEvent)
      .where(
        (e) => activeShowIds.isEmpty ||
          (e.relatedShowId != null && activeShowIds.contains(e.relatedShowId)),
      )
      .toList();

    final hasVisibleEvents = filteredShowEvents.isNotEmpty ||
      filteredCreatorEvents.isNotEmpty ||
      filteredTrashEvents.isNotEmpty;

    ref.listen<DatepickerState>(datepickerNotifierProvider, (previous, next) {
      if (previous?.selectedDate != next.selectedDate) {
        notifier.fetchResolvedEventsForDate(next.selectedDate);
      }
    });

    // Listener für Overlay-Schließung
    ref.listen<bool>(filterOverlayProvider, (previous, next) {
      if (previous == true && next == false) {
        // Overlay wurde geschlossen -> neu laden
        final datepickerState = ref.read(datepickerNotifierProvider);
        ref
            .read(calendarEventsNotifierProvider.notifier)
            .fetchResolvedEventsForDate(datepickerState.selectedDate);
      }
    });

    return Expanded(
      child: Stack(children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${DateFormat('EEEE', 'de_DE').format(datepickerState.selectedDate)}, ${DateFormat('dd', 'de_DE').format(datepickerState.selectedDate)}. ${DateFormat('MMMM', 'de_DE').format(datepickerState.selectedDate)}',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showEventTypeInfo(context),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white24,
                            ),
                            color: Colors.white.withOpacity(0.04),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '?',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (displayedResolvedEvents.isEmpty)
                  Text(
                    favoritesOnly
                        ? 'Keine Favoriten für diesen Tag.'
                        : 'Es wurden keine Events gefunden',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  )
                else if (!hasVisibleEvents)
                  Text(
                    'Keine Events passen zu deinen aktiven Filtern.',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: Colors.white54,
                    ),
                  )
                else
                  Flexible(
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          controller: _eventsScrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (streamingFilter.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 7),
                                  color: const Color(0xFFF890FF)
                                      .withValues(alpha: 0.08),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.filter_alt_rounded,
                                          color: Color(0xFFF890FF), size: 13),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Streaming-Filter: ${streamingFilter.join(' & ')}',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 12,
                                            color: const Color(0xFFF890FF),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (activeShowIds.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 7),
                                  color: const Color(0xFF0AA2A2)
                                      .withValues(alpha: 0.10),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.tv_rounded,
                                          color: Color(0xFF0AA2A2), size: 13),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Show-Filter: ${activeFiltersState.activeShows.map((show) => show.displayTitle).join(' • ')}',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 12,
                                            color: const Color(0xFF0AA2A2),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              _buildSection(
                                key: 'shows',
                                label: 'SHOWS',
                                accentColor: const Color(0xFFF890FF),
                                events: filteredShowEvents,
                                cardBuilder: (e) =>
                                    CalendarResolvedShowEventCard(event: e),
                              ),
                              if (selectedGenres.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 7),
                                  color: const Color(0xFFF890FF)
                                      .withValues(alpha: 0.08),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.category_rounded,
                                          color: Color(0xFFF890FF), size: 13),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Genre-Filter: ${selectedGenres.join(' & ')}',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 12,
                                            color: const Color(0xFFF890FF),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (selectedTrashCity != null)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 7),
                                  color: const Color(0xFFFFD700)
                                      .withValues(alpha: 0.08),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_city_rounded,
                                          color: Color(0xFFFFD700), size: 13),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Community-Stadt: $selectedTrashCity',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 12,
                                            color: const Color(0xFFFFD700),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              _buildSection(
                                key: 'creator',
                                label: 'CREATOR',
                                accentColor: const Color(0xFF4DB6FF),
                                events: filteredCreatorEvents,
                                cardBuilder: (e) =>
                                    CalendarCreatorEventCard(event: e),
                              ),
                              _buildSection(
                                key: 'community',
                                label: 'COMMUNITY',
                                accentColor: const Color(0xFFFFD700),
                                events: filteredTrashEvents,
                                cardBuilder: (e) =>
                                    CalendarTrashEventCard(event: e),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                        IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: _showTopScrollHint ? 1 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                height: 18,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xCC141414),
                                      Color(0x00141414),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: _showBottomScrollHint ? 1 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: 22,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0x00141414),
                                      Color(0xD9141414),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildSection({
    required String key,
    required String label,
    required Color accentColor,
    required List<dynamic> events,
    required Widget Function(dynamic) cardBuilder,
  }) {
    if (events.isEmpty) return const SizedBox.shrink();
    final expanded = _sectionExpanded[key] ?? true;

    final groupedEvents = key == 'shows'
        ? groupConsecutiveByKey<dynamic>(
            events,
            (event) =>
                event is ResolvedCalendarEvent ? event.relatedShowId : null,
          )
        : events
            .map(
              (event) => GroupedSequenceItem<dynamic>(item: event),
            )
            .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ───────────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _sectionExpanded[key] = !expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white54,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '${events.length}',
                      style: GoogleFonts.montserrat(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: Colors.white30,
                  ),
                ],
              ),
            ),
          ),
          // ── Cards ────────────────────────────────────────────────────────
          if (expanded)
            ...groupedEvents.map(
              (entry) => Padding(
                padding: EdgeInsets.only(
                  left: entry.isContinuation ? 18 : 0,
                  bottom: 8.0,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: entry.isContinuation
                                ? accentColor.withValues(alpha: 0.35)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Opacity(
                        opacity: entry.isContinuation ? 0.92 : 1,
                        child: cardBuilder(entry.item),
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

  void _showEventTypeInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1B1B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Text(
          'Was ist was?',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _EventTypeInfoRow(
              title: 'Shows',
              description:
                  'Reguläre TV- oder Streaming-Termine wie Episoden, Premieren, Reunionfolgen oder Finalfolgen.',
              color: Color(0xFFF890FF),
            ),
            SizedBox(height: 12),
            _EventTypeInfoRow(
              title: 'Creator',
              description:
                  'Begleitender Content von Creator:innen, zum Beispiel Reactions, Recaps oder Analysen.',
              color: Color(0xFF4DB6FF),
            ),
            SizedBox(height: 12),
            _EventTypeInfoRow(
              title: 'Community',
              description:
                  'Events rund um die Szene, zum Beispiel Watchpartys, Live-Shows oder Fan-Treffen.',
              color: Color(0xFFFFD700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Schließen',
              style: GoogleFonts.dmSans(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventTypeInfoRow extends StatelessWidget {
  final String title;
  final String description;
  final Color color;

  const _EventTypeInfoRow({
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: GoogleFonts.dmSans(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
