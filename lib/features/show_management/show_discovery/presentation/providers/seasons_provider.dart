import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/logger.dart';
import 'package:frontend/features/show_management/show_discovery/data/repositories/season_repository_impl.dart';
import 'package:frontend/features/show_management/show_discovery/data/sources/season_data_source.dart';
import 'package:frontend/features/show_management/show_discovery/domain/repositories/season_repository.dart';
import 'package:frontend/features/show_management/show_discovery/domain/use_cases/get_seasons_by_show_use_case.dart';
import 'package:logger/logger.dart';

class SearchState {
  final bool isLoading;
  final List<dynamic> seasons;
  final String errorMessage;

  SearchState({
    this.isLoading = false,
    this.seasons = const [],
    this.errorMessage = '',
  });

  SearchState copyWith({
    bool? isLoading,
    List<dynamic>? seasons,
    String? errorMessage,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      seasons: seasons ?? this.seasons,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SeasonsNotifier extends StateNotifier<SearchState> {
  final GetSeasonsByShowUseCase getSeasonsbyShowUseCase;
  final Logger _logger = getLogger('SeasonsNotifier');

  SeasonsNotifier(this.getSeasonsbyShowUseCase) : super(SearchState());

  Future<void> getSeasonsByShow(String showId) async {
    if (showId.isEmpty) return;

    _logger.i('Getting seasons with show: $showId');
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final results = await getSeasonsbyShowUseCase.execute(showId);
      _logger.i('Received seasons by show: $results');
      state = state.copyWith(isLoading: false, seasons: results);
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
final seasonsNotifierProvider =
    StateNotifierProvider<SeasonsNotifier, SearchState>((ref) {
  final getSeasonsByShowUseCase = ref.read(getSeasonsByShowUseCaseProvider);
  return SeasonsNotifier(getSeasonsByShowUseCase);
});

/// Provider für den Search Use Case (wird in der Domain-Schicht definiert)
final getSeasonsByShowUseCaseProvider = Provider<GetSeasonsByShowUseCase>((ref) {
  final seasonRepository = ref.read(seasonsRepositoryProvider);
  return GetSeasonsByShowUseCase(
    seasonRepository: seasonRepository,
  );
});

/// Provider für das `ShowRepository`
final seasonsRepositoryProvider = Provider<SeasonRepository>((ref) {
  final mockDataSource = ref.read(seasonsDataSourceProvider);
  return SeasonRepositoryImpl(mockDataSource);
});

/// Provider für die Mock-Datenquelle
final seasonsDataSourceProvider = Provider<SeasonDataSource>((ref) {
  return SeasonDataSource();
});
