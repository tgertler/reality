import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/show_management/show_discovery/domain/use_cases/get_show_by_id_use_case.dart';
import 'package:frontend/features/show_management/show_discovery/domain/entities/show.dart';
import '../../data/repositories/show_repository_impl.dart';
import '../../data/sources/show_data_source.dart';
import '../../domain/repositories/show_repository.dart';

class ShowState {
  final String id;
  final String title;
  final String description;
  final String genre;
  final String releaseWindow;
  final String headerImageUrl;
  final String mainColor;
  final bool isLoading;
  final String? errorMessage;

  ShowState({
    this.id = '',
    this.title = '',
    this.description = '',
    this.genre = '',
    this.releaseWindow = '',
    this.headerImageUrl = '',
    this.mainColor = '',
    this.isLoading = false,
    this.errorMessage,
  });

  ShowState copyWith({
    String? id,
    String? title,
    String? description,
    String? genre,
    String? releaseWindow,
    String? headerImageUrl,
    String? mainColor,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ShowState(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      genre: genre ?? this.genre,
      releaseWindow: releaseWindow ?? this.releaseWindow,
      headerImageUrl: headerImageUrl ?? this.headerImageUrl,
      mainColor: mainColor ?? this.mainColor,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ShowOverviewNotifier extends StateNotifier<ShowState> {
  final GetShowByIdUseCase getShowByIdUseCase;

  ShowOverviewNotifier(this.getShowByIdUseCase) : super(ShowState());

  Future<void> loadShow(String showId) async {
    state = ShowState(id: showId, isLoading: true);
    try {
      final Show show = await getShowByIdUseCase.execute(showId);
      state = state.copyWith(
        id: show.id,
        title: show.title ?? show.displayTitle,
        description: show.description,
        genre: show.genre?.trim() ?? '',
        releaseWindow: show.releaseWindow?.trim() ?? '',
        headerImageUrl: show.headerImageUrl?.trim() ?? '',
        mainColor: show.mainColor?.trim() ?? '',
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final showOverviewProvider = StateNotifierProvider<ShowOverviewNotifier, ShowState>((ref) {
  final getShowByIdUseCase = ref.read(getShowByIdUseCaseProvider);
  return ShowOverviewNotifier(getShowByIdUseCase);
});

/// Provider für den Search Use Case (wird in der Domain-Schicht definiert)
final getShowByIdUseCaseProvider = Provider<GetShowByIdUseCase>((ref) {
  final showRepository = ref.read(showRepositoryProvider);
  return GetShowByIdUseCase(
    showRepository: showRepository
  );
});

/// Provider für das `ShowRepository`
final showRepositoryProvider = Provider<ShowRepository>((ref) {
  final mockDataSource = ref.read(showDataSourceProvider);
  return ShowRepositoryImpl(mockDataSource);
});

/// Provider für die Mock-Datenquelle
final showDataSourceProvider = Provider<ShowDataSource>((ref) {
  return ShowDataSource();
});
