import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/show_management/show_discovery/data/repositories/season_repository_impl.dart';
import 'package:frontend/features/show_management/show_discovery/data/sources/season_data_source.dart';
import 'package:frontend/features/show_management/show_discovery/domain/entities/season.dart';
import 'package:frontend/features/show_management/show_discovery/domain/repositories/season_repository.dart';
import 'package:frontend/features/show_management/show_discovery/domain/use_cases/get_season_by_id_use_case.dart';

class SeasonState {
  final String id;
  final String showId;
  final int seasonNumber;
  final String? releaseFrequency;
  final DateTime startDate;
  final int totalEpisodes;
  final String? streamingOption;
  final bool isLoading;
  final String? errorMessage;

  SeasonState({
    required this.id,
    required this.showId,
    required this.seasonNumber,
    this.releaseFrequency,
    required this.startDate,
    required this.totalEpisodes,
    required this.streamingOption,
    this.isLoading = false,
    this.errorMessage,
  });

  SeasonState copyWith({
    String? id,
    String? showId,
    int? seasonNumber,
    String? releaseFrequency,
    DateTime? startDate,
    int? totalEpisodes,
    String? streamingOption,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SeasonState(
      id: id ?? this.id,
      showId: showId ?? this.showId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      releaseFrequency: releaseFrequency ?? this.releaseFrequency,
      startDate: startDate ?? this.startDate,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      streamingOption: streamingOption ?? this.streamingOption,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SeasonOverviewNotifier extends StateNotifier<SeasonState> {
  final GetSeasonByIdUseCase getSeasonByIdUseCase;

  SeasonOverviewNotifier(this.getSeasonByIdUseCase)
      : super(
          SeasonState(
            id: '',
            showId: '',
            seasonNumber: 0,
            startDate: DateTime.now(),
            totalEpisodes: 0,
            streamingOption: '',
          ),
        );

  Future<void> loadSeason(String seasonId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final Season season = await getSeasonByIdUseCase.execute(seasonId);
      state = state.copyWith(
        id: season.id,
        showId: season.showId,
        seasonNumber: season.seasonNumber,
        releaseFrequency: season.releaseFrequency,
        totalEpisodes: season.totalEpisodes,
        streamingOption: season.streamingOption,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final seasonOverviewProvider =
    StateNotifierProvider<SeasonOverviewNotifier, SeasonState>((ref) {
  final getSeasonByIdUseCase = ref.read(getSeasonByIdUseCaseProvider);
  return SeasonOverviewNotifier(getSeasonByIdUseCase);
});

/// Provider für den Search Use Case (wird in der Domain-Schicht definiert)
final getSeasonByIdUseCaseProvider = Provider<GetSeasonByIdUseCase>((ref) {
  final seasonRepository = ref.read(seasonRepositoryProvider);
  return GetSeasonByIdUseCase(seasonRepository: seasonRepository);
});

/// Provider für das `seasonRepository`
final seasonRepositoryProvider = Provider<SeasonRepository>((ref) {
  final mockDataSource = ref.read(seasonDataSourceProvider);
  return SeasonRepositoryImpl(mockDataSource);
});

/// Provider für die Mock-Datenquelle
final seasonDataSourceProvider = Provider<SeasonDataSource>((ref) {
  return SeasonDataSource();
});
