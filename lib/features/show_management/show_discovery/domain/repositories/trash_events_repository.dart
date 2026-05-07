import '../entities/trash_event.dart';

abstract class TrashEventsRepository {
  Future<List<TrashEvent>> getTrashEventsForShow(String showId);
}
