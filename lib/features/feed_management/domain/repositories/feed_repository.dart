import '../entities/feed_item_entity.dart';

abstract class FeedRepository {
  Future<List<FeedItemEntity>> getFeed(int page, int pageSize);
}
