import '../../domain/repositories/feed_repository.dart';
import '../../domain/entities/feed_item_entity.dart';
import '../datasources/feed_datasource.dart';
import '../models/feed_item.dart';

class FeedRepositoryImpl implements FeedRepository {
  final FeedDatasource _datasource;

  FeedRepositoryImpl(this._datasource);

  @override
  Future<List<FeedItemEntity>> getFeed(int page, int pageSize) async {
    final offset = page * pageSize;
    final rows = await _datasource.fetchFeedItems(offset, pageSize);
    return rows.map((row) => FeedItem.fromJson(row)).toList();
  }
}
