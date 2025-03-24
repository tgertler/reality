import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/supabase_provider.dart';
import 'package:logger/logger.dart';
import '../../../../core/utils/logger.dart';
import '../../data/repositories/content_repository_impl.dart';
import '../../data/sources/content_data_source.dart';
import '../../domain/entities/show.dart';
import '../../domain/entities/season.dart';
import '../../domain/entities/attendee.dart';
import '../../domain/use_cases/add_show.dart';
import '../../domain/use_cases/add_season.dart';
import '../../domain/use_cases/add_attendee.dart';
import '../../domain/use_cases/generate_calendar_events.dart';

class ContentState {
  final bool isLoading;
  final String errorMessage;

  ContentState({
    this.isLoading = false,
    this.errorMessage = '',
  });

  ContentState copyWith({
    bool? isLoading,
    String? errorMessage,
  }) {
    return ContentState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ContentNotifier extends StateNotifier<ContentState> {
  final AddShow addShowUseCase;
  final AddSeason addSeasonUseCase;
  final AddAttendee addAttendeeUseCase;
  final GenerateCalendarEvents generateCalendarEventsUseCase;
  final Logger _logger = getLogger('ContentNotifier');

  ContentNotifier(
    this.addShowUseCase,
    this.addSeasonUseCase,
    this.addAttendeeUseCase,
    this.generateCalendarEventsUseCase,
  ) : super(ContentState());

  Future<void> addShow(Show show) async {
    _logger.i('Adding show: $show');
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      await addShowUseCase.call(show);
      _logger.i('Show added successfully');
      state = state.copyWith(isLoading: false);
    } catch (e, stackTrace) {
      _logger.e('Error adding show', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> addSeason(Season season) async {
    _logger.i('Adding season: $season');
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      await addSeasonUseCase.call(season);
      _logger.i('Season added successfully');
      state = state.copyWith(isLoading: false);
    } catch (e, stackTrace) {
      _logger.e('Error adding season', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> addAttendee(Attendee attendee) async {
    _logger.i('Adding attendee: $attendee');
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      await addAttendeeUseCase.call(attendee);
      _logger.i('Attendee added successfully');
      state = state.copyWith(isLoading: false);
    } catch (e, stackTrace) {
      _logger.e('Error adding attendee', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> generateCalendarEvents(Season season) async {
    _logger.i('Generating calendar events for season: $season');
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      await generateCalendarEventsUseCase.call(season);
      _logger.i('Calendar events generated successfully');
      state = state.copyWith(isLoading: false);
    } catch (e, stackTrace) {
      _logger.e('Error generating calendar events', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final contentRepositoryProvider = Provider<ContentRepositoryImpl>((ref) {
  final supabaseClient = ref.read(supabaseClientProvider);
  final dataSource = ContentDataSource(supabaseClient);
  return ContentRepositoryImpl(dataSource);
});

final addShowProvider = Provider<AddShow>((ref) {
  final repository = ref.read(contentRepositoryProvider);
  return AddShow(repository);
});

final addSeasonProvider = Provider<AddSeason>((ref) {
  final repository = ref.read(contentRepositoryProvider);
  return AddSeason(repository);
});

final addAttendeeProvider = Provider<AddAttendee>((ref) {
  final repository = ref.read(contentRepositoryProvider);
  return AddAttendee(repository);
});

final generateCalendarEventsProvider = Provider<GenerateCalendarEvents>((ref) {
  final repository = ref.read(contentRepositoryProvider);
  return GenerateCalendarEvents(repository);
});

final contentNotifierProvider = StateNotifierProvider<ContentNotifier, ContentState>((ref) {
  final addShow = ref.read(addShowProvider);
  final addSeason = ref.read(addSeasonProvider);
  final addAttendee = ref.read(addAttendeeProvider);
  final generateCalendarEvents = ref.read(generateCalendarEventsProvider);
  return ContentNotifier(addShow, addSeason, addAttendee, generateCalendarEvents);
});