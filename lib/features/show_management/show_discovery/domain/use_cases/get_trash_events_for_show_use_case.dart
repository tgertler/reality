import '../entities/trash_event.dart';
import '../repositories/trash_events_repository.dart';

class GetTrashEventsForShowUseCase {
  final TrashEventsRepository repository;

  GetTrashEventsForShowUseCase(this.repository);

  Future<List<TrashEvent>> execute(String showId) =>
      repository.getTrashEventsForShow(showId);
}
