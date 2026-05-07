import '../entities/creator_event.dart';
import '../repositories/creator_events_repository.dart';

class GetCreatorEventsForShowUseCase {
  final CreatorEventsRepository repository;

  GetCreatorEventsForShowUseCase(this.repository);

  Future<List<CreatorEvent>> execute(String showId) =>
      repository.getCreatorEventsForShow(showId);
}
