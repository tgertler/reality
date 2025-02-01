import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/logger.dart';
import 'package:logger/logger.dart';
import '../../data/sources/attendee_data_source.dart';
import '../../data/sources/show_data_source.dart';
import '../../domain/use_cases/search_shows_and_attendees_use_case.dart';
import '../../data/repositories/show_repository_impl.dart';
import '../../data/repositories/attendee_repository_impl.dart';
import '../../domain/repositories/attendee_repository.dart';
import '../../domain/repositories/show_repository.dart';
import '../../../../../core/utils/supabase_provider.dart';

class SearchState {
  final bool isLoading;
  final List<dynamic> results;
  final String errorMessage;

  SearchState({
    this.isLoading = false,
    this.results = const [],
    this.errorMessage = '',
  });

  SearchState copyWith({
    bool? isLoading,
    List<dynamic>? results,
    String? errorMessage,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final SearchShowsAndAttendeesUseCase searchUseCase;
  final Logger _logger = getLogger('SearchNotifier');

  SearchNotifier(this.searchUseCase) : super(SearchState());

  Future<void> search(String query) async {
    if (query.isEmpty) return;

    _logger.i('Starting search with query: $query');
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final results = await searchUseCase.execute(query);
      _logger.i('Search results received: $results');
      state = state.copyWith(isLoading: false, results: results);
    } catch (e, stackTrace) {
      _logger.e('Error during search', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void clearSearch() {
    _logger.e('Clearing search results');
    state = SearchState();
  }
}

/// Riverpod Provider für den `SearchNotifier`
final searchNotifierProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final searchUseCase = ref.read(searchUseCaseProvider);
  return SearchNotifier(searchUseCase);
});

/// Provider für den Search Use Case (wird in der Domain-Schicht definiert)
final searchUseCaseProvider = Provider<SearchShowsAndAttendeesUseCase>((ref) {
  final showRepository = ref.read(showRepositoryProvider);
  final attendeeRepository = ref.read(attendeeRepositoryProvider);
  return SearchShowsAndAttendeesUseCase(
    showRepository: showRepository,
    attendeeRepository: attendeeRepository,
  );
});

/// Provider für das `ShowRepository`
final showRepositoryProvider = Provider<ShowRepository>((ref) {
  final mockDataSource = ref.read(showDataSourceProvider);
  return ShowRepositoryImpl(mockDataSource);
});

/// Provider für das `AttendeeRepository`
final attendeeRepositoryProvider = Provider<AttendeeRepository>((ref) {
  final mockDataSource = ref.read(attendeeDataSourceProvider);
  return AttendeeRepositoryImpl(mockDataSource);
});

/// Provider für die Mock-Datenquelle
final showDataSourceProvider = Provider<ShowDataSource>((ref) {
  final supabaseClient = ref.read(supabaseClientProvider);
  return ShowDataSource(supabaseClient);
});

/// Provider für die Mock-Datenquelle
final attendeeDataSourceProvider = Provider<AttendeeDataSource>((ref) {
  final supabaseClient = ref.read(supabaseClientProvider);
  return AttendeeDataSource(supabaseClient);
});
