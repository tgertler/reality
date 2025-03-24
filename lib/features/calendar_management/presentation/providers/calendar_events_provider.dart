import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/calendar_management/presentation/providers/filter_active_provider.dart';
import 'package:logger/logger.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../core/utils/supabase_provider.dart';
import '../../data/sources/calendar_event_datasource.dart';
import '../../data/repositories/calendar_event_repository_impl.dart';
import '../../domain/entities/calendar_event_with_show.dart';
import '../../domain/repositories/calendar_event_repository.dart';
import '../../domain/use_cases/get_calendar_events_with_shows_for_date.dart';
import '../../domain/use_cases/get_next_three_premieres.dart';
import '../../domain/use_cases/get_last_three_premieres.dart';

class CalendarEventsState {
  final bool isLoading;
  final List<CalendarEventWithShow> events;
  final List<CalendarEventWithShow> nextPremieres;
  final List<CalendarEventWithShow> lastPremieres;
  final String errorMessage;

  CalendarEventsState({
    this.isLoading = false,
    this.events = const [],
    this.nextPremieres = const [],
    this.lastPremieres = const [],
    this.errorMessage = '',
  });

  CalendarEventsState copyWith({
    bool? isLoading,
    List<CalendarEventWithShow>? events,
    List<CalendarEventWithShow>? nextPremieres,
    List<CalendarEventWithShow>? lastPremieres,
    String? errorMessage,
  }) {
    return CalendarEventsState(
      isLoading: isLoading ?? this.isLoading,
      events: events ?? this.events,
      nextPremieres: nextPremieres ?? this.nextPremieres,
      lastPremieres: lastPremieres ?? this.lastPremieres,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class CalendarEventsNotifier extends StateNotifier<CalendarEventsState> {
  final GetCalendarEventsWithShowsForDate getCalendarEventsForDate;
  final GetNextThreePremieres getNextThreePremieres;
  final GetLastThreePremieres getLastThreePremieres;
  final Logger _logger = getLogger('CalendarEventsNotifier');
  final ActiveFiltersNotifier activeFiltersNotifier;

  CalendarEventsNotifier(
      this.getCalendarEventsForDate,
      this.activeFiltersNotifier,
      this.getNextThreePremieres,
      this.getLastThreePremieres)
      : super(CalendarEventsState());

  Future<void> fetchEventsForDate(DateTime date) async {
    _logger.i('Fetching events for date: $date');

    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final activeShows = activeFiltersNotifier.state.activeShows
          .map((show) => show.showId)
          .toList();
      final activeAttendees = activeFiltersNotifier.state.activeAttendees
          .map((attendee) => attendee.id)
          .toList();
      final events = await getCalendarEventsForDate.execute(
          date, activeShows, activeAttendees);
      _logger.i('Events received: $events');
      state = state.copyWith(isLoading: false, events: events);
    } catch (e, stackTrace) {
      _logger.e('Error fetching events', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> fetchEventsReleasingToday() async {
    _logger.i('Fetching shows releasing today');
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final events =
          await getCalendarEventsForDate.execute(DateTime.now(), [], []);
      _logger.i('Shows releasing today received: $events');
      state = state.copyWith(isLoading: false, events: events);
    } catch (e, stackTrace) {
      _logger.e('Error fetching shows releasing today', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> fetchNextThreePremieres() async {
    _logger.i('Fetching next three premieres');
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final nextPremieres = await getNextThreePremieres.execute();
      _logger.i('Next three premieres received: $nextPremieres');
      state = state.copyWith(isLoading: false, nextPremieres: nextPremieres);
    } catch (e, stackTrace) {
      _logger.e('Error fetching next three premieres', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> fetchLastThreePremieres() async {
    _logger.i('Fetching last three releases');
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final lastPremieres = await getLastThreePremieres.execute();
      _logger.i('Last three releases received: $lastPremieres');
      state = state.copyWith(isLoading: false, lastPremieres: lastPremieres);
    } catch (e, stackTrace) {
      _logger.e('Error fetching last three releases', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

/// Riverpod Provider für den `CalendarEventsNotifier`
final calendarEventsNotifierProvider =
    StateNotifierProvider<CalendarEventsNotifier, CalendarEventsState>((ref) {
  final getCalendarEventsWithShowsForDate =
      ref.read(getCalendarEventsWithShowsForDateProvider);
  final activeFiltersNotifier = ref.read(activeFiltersProvider.notifier);
  final getNextThreePremieres = ref.read(getNextThreePremieresProvider);
  final getLastThreePremieres = ref.read(getLastThreePremieresProvider);
  return CalendarEventsNotifier(getCalendarEventsWithShowsForDate,
      activeFiltersNotifier, getNextThreePremieres, getLastThreePremieres);
});

/// Provider für den `GetCalendarEventsForDate` Use Case
final getCalendarEventsWithShowsForDateProvider =
    Provider<GetCalendarEventsWithShowsForDate>((ref) {
  final calendarEventRepository = ref.read(calendarEventRepositoryProvider);
  return GetCalendarEventsWithShowsForDate(calendarEventRepository);
});

/// Provider für den `GetNextThreePremieres` Use Case
final getNextThreePremieresProvider = Provider<GetNextThreePremieres>((ref) {
  final calendarEventRepository = ref.read(calendarEventRepositoryProvider);
  return GetNextThreePremieres(calendarEventRepository);
});

/// Provider für den `GetLastThreePremieres` Use Case
final getLastThreePremieresProvider = Provider<GetLastThreePremieres>((ref) {
  final calendarEventRepository = ref.read(calendarEventRepositoryProvider);
  return GetLastThreePremieres(calendarEventRepository);
});

/// Provider für das `CalendarEventRepository`
final calendarEventRepositoryProvider =
    Provider<CalendarEventRepository>((ref) {
  final dataSource = ref.read(calendarEventDataSourceProvider);
  return CalendarEventRepositoryImpl(dataSource);
});

/// Provider für die Mock-Datenquelle
final calendarEventDataSourceProvider =
    Provider<CalendarEventDataSource>((ref) {
  final supabaseClient = ref.read(supabaseClientProvider);

  return CalendarEventDataSource(supabaseClient);
});
