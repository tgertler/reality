import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/supabase_provider.dart';
import 'package:frontend/features/calendar_management/data/repositories/calendar_event_repository_impl.dart';
import 'package:frontend/features/calendar_management/data/sources/calendar_event_datasource.dart';
import 'package:frontend/features/calendar_management/domain/entities/calendar_event_with_show.dart';
import 'package:frontend/features/calendar_management/domain/repositories/calendar_event_repository.dart';
import 'package:frontend/features/calendar_management/domain/use_cases/get_next_calendar_event_for_show.dart';
import 'package:frontend/features/calendar_management/domain/use_cases/get_upcoming_calendar_events_for_show.dart';
import 'package:logger/logger.dart';
import '../../../../../core/utils/logger.dart';

/// State für Show-Events (Next + Upcoming)
class ShowEventsState {
  final CalendarEventWithShow? nextEvent;
  final List<CalendarEventWithShow> upcomingEvents;
  final bool isLoadingNext;
  final bool isLoadingUpcoming;
  final String errorMessage;

  ShowEventsState({
    this.nextEvent,
    this.upcomingEvents = const [],
    this.isLoadingNext = false,
    this.isLoadingUpcoming = false,
    this.errorMessage = '',
  });

  ShowEventsState copyWith({
    CalendarEventWithShow? nextEvent,
    List<CalendarEventWithShow>? upcomingEvents,
    bool? isLoadingNext,
    bool? isLoadingUpcoming,
    String? errorMessage,
  }) {
    return ShowEventsState(
      nextEvent: nextEvent ?? this.nextEvent,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      isLoadingNext: isLoadingNext ?? this.isLoadingNext,
      isLoadingUpcoming: isLoadingUpcoming ?? this.isLoadingUpcoming,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Notifier für Show-Events
class ShowEventsNotifier extends StateNotifier<ShowEventsState> {
  final GetNextCalendarEventForShow getNextEvent;
  final GetUpcomingEventsForShow getUpcomingEvents;
  final Logger _logger = getLogger('ShowEventsNotifier');

  ShowEventsNotifier(this.getNextEvent, this.getUpcomingEvents)
      : super(ShowEventsState());

  Future<void> fetchNextEvent(String showId) async {
    _logger.i('Fetching next event for show: $showId');
    state = state.copyWith(isLoadingNext: true, errorMessage: '');

    try {
      final nextEvent = await getNextEvent.execute(showId);
      _logger.i('Next event received: $nextEvent');
      state = state.copyWith(isLoadingNext: false, nextEvent: nextEvent);
    } catch (e, stackTrace) {
      _logger.e('Error fetching next event', e, stackTrace);
      state = state.copyWith(
        isLoadingNext: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> fetchUpcomingEvents(String showId) async {
    _logger.i('Fetching upcoming events for show: $showId');
    state = state.copyWith(isLoadingUpcoming: true, errorMessage: '');

    try {
      final events = await getUpcomingEvents.execute(showId);
      _logger.i('Upcoming events received: ${events.length}');
      state = state.copyWith(isLoadingUpcoming: false, upcomingEvents: events);
    } catch (e, stackTrace) {
      _logger.e('Error fetching upcoming events', e, stackTrace);
      state = state.copyWith(
        isLoadingUpcoming: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Beide gleichzeitig laden
  Future<void> loadAllShowEvents(String showId) async {
    await Future.wait([
      fetchNextEvent(showId),
      fetchUpcomingEvents(showId),
    ]);
  }
}

/// Provider für Show-Events
final showEventsProvider =
    StateNotifierProvider<ShowEventsNotifier, ShowEventsState>((ref) {
  final getNextEvent = ref.read(getNextCalendarEventForShowProvider);
  final getUpcomingEvents = ref.read(getUpcomingCalendarEventsForShowProvider);
  return ShowEventsNotifier(getNextEvent, getUpcomingEvents);
});

/// Provider für `GetUpcomingCalendarEventsForShow` Use Case
final getUpcomingCalendarEventsForShowProvider =
    Provider<GetUpcomingEventsForShow>((ref) {
  final calendarEventRepository = ref.read(calendarEventRepositoryProvider);
  return GetUpcomingEventsForShow(calendarEventRepository);
});

/// Provider für `GetNextCalendarEventForShow` Use Case
final getNextCalendarEventForShowProvider =
    Provider<GetNextCalendarEventForShow>((ref) {
  final calendarEventRepository = ref.read(calendarEventRepositoryProvider);
  return GetNextCalendarEventForShow(calendarEventRepository);
});

/// Provider für `CalendarEventRepository`
final calendarEventRepositoryProvider =
    Provider<CalendarEventRepository>((ref) {
  final dataSource = ref.read(calendarEventDataSourceProvider);
  return CalendarEventRepositoryImpl(dataSource);
});

/// Provider für die Datenquelle
final calendarEventDataSourceProvider =
    Provider<CalendarEventDataSource>((ref) {
  final supabaseClient = ref.read(supabaseClientProvider);
  return CalendarEventDataSource(supabaseClient);
});
