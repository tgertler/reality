import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/feed_management/data/datasources/feed_datasource.dart';
import 'package:frontend/features/feed_management/data/repositories/feed_repository_impl.dart';
import 'package:frontend/features/feed_management/data/models/feed_item.dart';
import 'package:frontend/features/feed_management/domain/repositories/feed_repository.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepositoryImpl(FeedDatasource());
});

final feedControllerProvider =
    StateNotifierProvider<FeedController, AsyncValue<List<FeedItem>>>((ref) {
  return FeedController(ref.read(feedRepositoryProvider));
});

class FeedController extends StateNotifier<AsyncValue<List<FeedItem>>> {
  FeedController(this._repository) : super(const AsyncValue.loading());

  final FeedRepository _repository;
  int _page = 0;
  final int _pageSize = 8;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  Future<void> loadInitial() async {
    state = const AsyncValue.loading();
    _page = 0;
    _hasMore = true;

    try {
      final items = await _repository.getFeed(_page, _pageSize);
      final feedItems = items.cast<FeedItem>();
      _hasMore = feedItems.length == _pageSize;
      state = AsyncValue.data(feedItems);
    } catch (error, stack) {
      state = AsyncValue.error(error, stackTrace: stack);
    }
  }

  Future<void> loadMore() async {
    if (!mounted || !_hasMore) return;
    final currentState = state;
    if (currentState is AsyncLoading<List<FeedItem>>) return;

    final currentItems = currentState.value ?? [];
    _page += 1;

    try {
      final nextPage = await _repository.getFeed(_page, _pageSize);
      final newItems = nextPage.cast<FeedItem>();
      _hasMore = newItems.length == _pageSize;
      state = AsyncValue.data([...currentItems, ...newItems]);
    } catch (error, stack) {
      state = AsyncValue.error(error, stackTrace: stack);
    }
  }
}
