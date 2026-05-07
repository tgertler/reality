import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/supabase_provider.dart';

import '../../data/repositories/creator_events_repository_impl.dart';
import '../../data/sources/creator_events_datasource.dart';
import '../../domain/entities/creator_event.dart';
import '../../domain/use_cases/get_creator_events_for_show_use_case.dart';

final _creatorEventsDataSourceProvider =
    Provider<CreatorEventsDataSource>((ref) {
  return CreatorEventsDataSource(ref.read(supabaseClientProvider));
});

final _creatorEventsRepositoryProvider =
    Provider<CreatorEventsRepositoryImpl>((ref) {
  return CreatorEventsRepositoryImpl(
      ref.read(_creatorEventsDataSourceProvider));
});

/// Creator events for a specific show (keyed by showId)
final creatorEventsProvider =
    FutureProvider.family<List<CreatorEvent>, String>((ref, showId) async {
  final useCase = GetCreatorEventsForShowUseCase(
      ref.read(_creatorEventsRepositoryProvider));
  return useCase.execute(showId);
});
