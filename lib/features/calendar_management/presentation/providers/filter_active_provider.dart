import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/attendee.dart';
import '../../domain/entities/show.dart';

class ActiveFiltersState {
  final List<Show> activeShows;
  final List<Attendee> activeAttendees;

  ActiveFiltersState({this.activeShows = const [], this.activeAttendees = const []});


  ActiveFiltersState copyWith({List<Show>? activeShows, List<Attendee>? activeAttendees}) {
    return ActiveFiltersState(
      activeShows: activeShows ?? this.activeShows,
      activeAttendees: activeAttendees ?? this.activeAttendees,
    );
  }
}

class ActiveFiltersNotifier extends StateNotifier<ActiveFiltersState> {
  ActiveFiltersNotifier() : super(ActiveFiltersState());

  void addShow(String showId, String title, {String? genre}) {
    if (!state.activeShows.any((show) => show.showId == showId)) {
      state = state.copyWith(
        activeShows: [
          ...state.activeShows,
          Show(showId: showId, title: title, genre: genre),
        ],
      );
    }
  }

  void removeShow(String showId) {
    state = state.copyWith(
      activeShows: state.activeShows.where((show) => show.showId != showId).toList(),
    );
  }

    void addAttendee(String attendeeId, String attendeeName) {
    if (!state.activeAttendees.any((attendee) => attendee.id == attendeeId)) {
      state = state.copyWith(
        activeAttendees: [...state.activeAttendees, Attendee(id: attendeeId, name: attendeeName)],
      );
    }
  }

  void removeAttendee(String attendeeId) {
    state = state.copyWith(
      activeAttendees: state.activeAttendees.where((attendee) => attendee.id != attendeeId).toList(),
    );
  }
}

final activeFiltersProvider = StateNotifierProvider<ActiveFiltersNotifier, ActiveFiltersState>((ref) {
  return ActiveFiltersNotifier();
});