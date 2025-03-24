import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/supabase_provider.dart';
import 'package:frontend/features/favorites_management/domain/repositories/favorites_repository.dart';
import 'package:logger/logger.dart';
import 'package:frontend/features/favorites_management/domain/entities/show.dart';
import 'package:frontend/features/favorites_management/domain/entities/attendee.dart';
import 'package:frontend/features/favorites_management/domain/use_cases/get_favorite_shows_use_case.dart';
import 'package:frontend/features/favorites_management/domain/use_cases/get_favorite_attendees_use_case.dart';
import 'package:frontend/features/favorites_management/domain/use_cases/add_favorite_show_use_case.dart';
import 'package:frontend/features/favorites_management/domain/use_cases/remove_favorite_show_use_case.dart';
import 'package:frontend/features/favorites_management/domain/use_cases/add_favorite_attendee_use_case.dart';
import 'package:frontend/features/favorites_management/domain/use_cases/remove_favorite_attendee.dart';
import 'package:frontend/features/favorites_management/domain/use_cases/is_favorite_show_use_case.dart';
import 'package:frontend/features/favorites_management/domain/use_cases/is_favorite_attendee_use_case.dart';
import '../../../../../core/utils/logger.dart';
import '../../data/repositories/favorites_repository_impl.dart';
import '../../data/sources/favorites_data_source.dart';

class FavoritesState {
  final bool isLoading;
  final List<Show> favoriteShows;
  final List<Attendee> favoriteAttendees;
  final String errorMessage;

  FavoritesState({
    this.isLoading = false,
    this.favoriteShows = const [],
    this.favoriteAttendees = const [],
    this.errorMessage = '',
  });

  FavoritesState copyWith({
    bool? isLoading,
    List<Show>? favoriteShows,
    List<Attendee>? favoriteAttendees,
    String? errorMessage,
  }) {
    return FavoritesState(
      isLoading: isLoading ?? this.isLoading,
      favoriteShows: favoriteShows ?? this.favoriteShows,
      favoriteAttendees: favoriteAttendees ?? this.favoriteAttendees,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class FavoritesNotifier extends StateNotifier<FavoritesState> {
  final GetFavoriteShows getFavoriteShows;
  final GetFavoriteAttendees getFavoriteAttendees;
  final AddFavoriteShow addFavoriteShow;
  final RemoveFavoriteShow removeFavoriteShow;
  final AddFavoriteAttendee addFavoriteAttendee;
  final RemoveFavoriteAttendee removeFavoriteAttendee;
  final IsFavoriteShow isFavoriteShow;
  final IsFavoriteAttendee isFavoriteAttendee;
  final Logger _logger = getLogger('FavoritesNotifier');

  FavoritesNotifier(
    this.getFavoriteShows,
    this.getFavoriteAttendees,
    this.addFavoriteShow,
    this.removeFavoriteShow,
    this.addFavoriteAttendee,
    this.removeFavoriteAttendee,
    this.isFavoriteShow,
    this.isFavoriteAttendee,
  ) : super(FavoritesState());

  Future<void> fetchFavoriteShows(String userId) async {
    _logger.i('Fetching favorite shows for user: $userId');
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final shows = await getFavoriteShows.call(userId);
      _logger.i('Favorite shows received: $shows');
      state = state.copyWith(isLoading: false, favoriteShows: shows);
    } catch (e, stackTrace) {
      _logger.e('Error fetching favorite shows', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> fetchFavoriteAttendees(String userId) async {
    _logger.i('Fetching favorite attendees for user: $userId');
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final attendees = await getFavoriteAttendees.call(userId);
      _logger.i('Favorite attendees received: $attendees');
      state = state.copyWith(isLoading: false, favoriteAttendees: attendees);
    } catch (e, stackTrace) {
      _logger.e('Error fetching favorite attendees', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> addShowToFavorites(String userId, String showId, String title) async {
    _logger.i('Adding show to favorites for user: $userId');
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      await addFavoriteShow.call(userId, showId, title);
      await fetchFavoriteShows(userId);
    } catch (e, stackTrace) {
      _logger.e('Error adding show to favorites', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> removeShowFromFavorites(String userId, String showId) async {
    _logger.i('Removing show from favorites for user: $userId');
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      await removeFavoriteShow.call(userId, showId);
      await fetchFavoriteShows(userId);
    } catch (e, stackTrace) {
      _logger.e('Error removing show from favorites', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> addAttendeeToFavorites(String userId, String attendeeId) async {
    _logger.i('Adding attendee to favorites for user: $userId');
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      await addFavoriteAttendee.call(userId, attendeeId);
      await fetchFavoriteAttendees(userId);
    } catch (e, stackTrace) {
      _logger.e('Error adding attendee to favorites', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> removeAttendeeFromFavorites(String userId, String attendeeId) async {
    _logger.i('Removing attendee from favorites for user: $userId');
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      await removeFavoriteAttendee.call(userId, attendeeId);
      await fetchFavoriteAttendees(userId);
    } catch (e, stackTrace) {
      _logger.e('Error removing attendee from favorites', e, stackTrace);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> isShowFavorite(String userId, String showId) async {
    return await isFavoriteShow.call(userId, showId);
  }

  Future<bool> isAttendeeFavorite(String userId, String attendeeId) async {
    return await isFavoriteAttendee.call(userId, attendeeId);
  }
}

/// Riverpod Provider für den `FavoritesNotifier`
final favoritesNotifierProvider =
    StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
  final getFavoriteShows = ref.read(getFavoriteShowsProvider);
  final getFavoriteAttendees = ref.read(getFavoriteAttendeesProvider);
  final addFavoriteShow = ref.read(addFavoriteShowProvider);
  final removeFavoriteShow = ref.read(removeFavoriteShowProvider);
  final addFavoriteAttendee = ref.read(addFavoriteAttendeeProvider);
  final removeFavoriteAttendee = ref.read(removeFavoriteAttendeeProvider);
  final isFavoriteShow = ref.read(isFavoriteShowProvider);
  final isFavoriteAttendee = ref.read(isFavoriteAttendeeProvider);
  return FavoritesNotifier(
    getFavoriteShows,
    getFavoriteAttendees,
    addFavoriteShow,
    removeFavoriteShow,
    addFavoriteAttendee,
    removeFavoriteAttendee,
    isFavoriteShow,
    isFavoriteAttendee,
  );
});

/// Provider für den `GetFavoriteShows` Use Case
final getFavoriteShowsProvider = Provider<GetFavoriteShows>((ref) {
  final favoritesRepository = ref.read(favoritesRepositoryProvider);
  return GetFavoriteShows(favoritesRepository);
});

/// Provider für den `GetFavoriteAttendees` Use Case
final getFavoriteAttendeesProvider = Provider<GetFavoriteAttendees>((ref) {
  final favoritesRepository = ref.read(favoritesRepositoryProvider);
  return GetFavoriteAttendees(favoritesRepository);
});

/// Provider für den `AddFavoriteShow` Use Case
final addFavoriteShowProvider = Provider<AddFavoriteShow>((ref) {
  final favoritesRepository = ref.read(favoritesRepositoryProvider);
  return AddFavoriteShow(favoritesRepository);
});

/// Provider für den `RemoveFavoriteShow` Use Case
final removeFavoriteShowProvider = Provider<RemoveFavoriteShow>((ref) {
  final favoritesRepository = ref.read(favoritesRepositoryProvider);
  return RemoveFavoriteShow(favoritesRepository);
});

/// Provider für den `AddFavoriteAttendee` Use Case
final addFavoriteAttendeeProvider = Provider<AddFavoriteAttendee>((ref) {
  final favoritesRepository = ref.read(favoritesRepositoryProvider);
  return AddFavoriteAttendee(favoritesRepository);
});

/// Provider für den `RemoveFavoriteAttendee` Use Case
final removeFavoriteAttendeeProvider = Provider<RemoveFavoriteAttendee>((ref) {
  final favoritesRepository = ref.read(favoritesRepositoryProvider);
  return RemoveFavoriteAttendee(favoritesRepository);
});

/// Provider für den `IsFavoriteShow` Use Case
final isFavoriteShowProvider = Provider<IsFavoriteShow>((ref) {
  final favoritesRepository = ref.read(favoritesRepositoryProvider);
  return IsFavoriteShow(favoritesRepository);
});

/// Provider für den `IsFavoriteAttendee` Use Case
final isFavoriteAttendeeProvider = Provider<IsFavoriteAttendee>((ref) {
  final favoritesRepository = ref.read(favoritesRepositoryProvider);
  return IsFavoriteAttendee(favoritesRepository);
});

/// Provider für das `FavoritesRepository`
final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final dataSource = ref.read(favoritesDataSourceProvider);
  return FavoritesRepositoryImpl(dataSource);
});

/// Provider für die Mock-Datenquelle
final favoritesDataSourceProvider = Provider<FavoritesDataSource>((ref) {
  final supabaseClient = ref.read(supabaseClientProvider);
  return FavoritesDataSource(supabaseClient);
});