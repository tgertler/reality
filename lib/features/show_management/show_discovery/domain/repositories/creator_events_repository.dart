import '../entities/creator_event.dart';

abstract class CreatorEventsRepository {
  Future<List<CreatorEvent>> getCreatorEventsForShow(String showId);
}
