import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/supabase_provider.dart';

import '../../data/repositories/trash_events_repository_impl.dart';
import '../../data/sources/trash_events_datasource.dart';
import '../../domain/entities/trash_event.dart';
import '../../domain/use_cases/get_trash_events_for_show_use_case.dart';

final _trashEventsDataSourceProvider =
    Provider<TrashEventsDataSource>((ref) {
  return TrashEventsDataSource(ref.read(supabaseClientProvider));
});

final _trashEventsRepositoryProvider =
    Provider<TrashEventsRepositoryImpl>((ref) {
  return TrashEventsRepositoryImpl(ref.read(_trashEventsDataSourceProvider));
});

/// Trash/community events for a specific show (keyed by showId)
final trashEventsProvider =
    FutureProvider.family<List<TrashEvent>, String>((ref, showId) async {
  final useCase =
      GetTrashEventsForShowUseCase(ref.read(_trashEventsRepositoryProvider));
  return useCase.execute(showId);
});
