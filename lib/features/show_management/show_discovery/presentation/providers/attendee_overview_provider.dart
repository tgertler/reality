import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/show_management/show_discovery/data/repositories/attendee_repository_impl.dart';
import 'package:frontend/features/show_management/show_discovery/data/sources/attendee_data_source.dart';
import 'package:frontend/features/show_management/show_discovery/domain/entities/attendee.dart';
import 'package:frontend/features/show_management/show_discovery/domain/repositories/attendee_repository.dart';
import 'package:frontend/features/show_management/show_discovery/domain/use_cases/get_attendee_by_id_use_case.dart';
import 'package:frontend/features/show_management/show_discovery/domain/use_cases/get_show_by_id_use_case.dart';
import 'package:frontend/features/show_management/show_discovery/domain/entities/show.dart';

import '../../../../../core/utils/supabase_provider.dart';
import '../../data/repositories/show_repository_impl.dart';
import '../../data/sources/show_data_source.dart';
import '../../domain/repositories/show_repository.dart';

class AttendeeState {
  final String id;
  final String name;
  final String bio;
  final bool isLoading;
  final String? errorMessage;

  AttendeeState({
    this.id = '',
    this.name = '',
    this.bio = '',
    this.isLoading = false,
    this.errorMessage,
  });

  AttendeeState copyWith({
    String? id,
    String? name,
    String? bio,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AttendeeState(
      id: id ?? this.id,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AttendeeOverviewNotifier extends StateNotifier<AttendeeState> {
  final GetAttendeeByIdUseCase getAttendeeByIdUseCase;

  AttendeeOverviewNotifier(this.getAttendeeByIdUseCase) : super(AttendeeState());

  Future<void> loadAttendee(String attendeeId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final Attendee attendee = await getAttendeeByIdUseCase.execute(attendeeId);
      state = state.copyWith(
        id: attendee.id,
        name: attendee.name,
        bio: attendee.bio,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final attendeeOverviewProvider = StateNotifierProvider<AttendeeOverviewNotifier, AttendeeState>((ref) {
  final getAttendeeByIdUseCase = ref.read(getAttendeeByIdUseCaseProvider);
  return AttendeeOverviewNotifier(getAttendeeByIdUseCase);
});

/// Provider für den Search Use Case (wird in der Domain-Schicht definiert)
final getAttendeeByIdUseCaseProvider = Provider<GetAttendeeByIdUseCase>((ref) {
  final attendeeRepository = ref.read(attendeeRepositoryProvider);
  return GetAttendeeByIdUseCase(
    attendeeRepository: attendeeRepository
  );
});

/// Provider für das `AttendeeRepository`
final attendeeRepositoryProvider = Provider<AttendeeRepository>((ref) {
  final mockDataSource = ref.read(attendeeDataSourceProvider);
  return AttendeeRepositoryImpl(mockDataSource);
});

/// Provider für die Mock-Datenquelle
final attendeeDataSourceProvider = Provider<AttendeeDataSource>((ref) {
  final supabaseClient = ref.read(supabaseClientProvider);

  return AttendeeDataSource(supabaseClient);
});
