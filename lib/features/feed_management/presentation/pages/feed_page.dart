import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/widgets/loading/app_skeleton.dart';
import 'package:frontend/core/widgets/top_bar_widget.dart';
import 'package:frontend/features/feed_management/presentation/controllers/feed_controller.dart';
import 'package:frontend/features/feed_management/presentation/widgets/feed_item_renderer.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedControllerProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedControllerProvider);

    return Scaffold(
      appBar: TopBarWidget(),
      backgroundColor: Colors.white,
      body: feedState.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No feed items available yet.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final visibleItems = items.where((item) {
            final type =
                item.itemType.toLowerCase().replaceAll('-', '_');
            if (type == 'next_3_premieres_block') {
              final raw = item.data['items'];
              if (raw == null) return false;
              if (raw is List) return raw.isNotEmpty;
              return false;
            }
            if (type == 'generic_bingo_stats_block' ||
                type == 'bingo_stats_block') {
              final raw = item.data['items'] ?? item.data;
              if (raw == null) return false;
              if (raw is List) return raw.isNotEmpty;
              if (raw is Map) return raw.isNotEmpty;
              return false;
            }
            return true;
          }).toList();

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: visibleItems.length,
            onPageChanged: (index) {
              if (index >= visibleItems.length - 2 &&
                  ref.read(feedControllerProvider.notifier).hasMore) {
                ref.read(feedControllerProvider.notifier).loadMore();
              }
            },
            itemBuilder: (context, index) {
              final item = visibleItems[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 0.0, vertical: 0.0),
                child: FeedItemRenderer(feedItem: item),
              );
            },
          );
        },
        loading: () => const _FeedPageSkeleton(),
        error: (error, stack) {
          return Center(
            child: Text(
              'Failed to load feed: ${error.toString()}',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        },
      ),
    );
  }
}

class _FeedPageSkeleton extends StatelessWidget {
  const _FeedPageSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 18.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
        ),
        child: const Padding(
          padding: EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeletonBox(width: 110, height: 18),
              SizedBox(height: 18),
              AppSkeletonBox(width: double.infinity, height: 280, borderRadius: BorderRadius.all(Radius.circular(16))),
              SizedBox(height: 18),
              AppSkeletonLines(lines: 3, height: 14, widths: [0.8, 1, 0.55]),
              SizedBox(height: 22),
              Row(
                children: [
                  AppSkeletonCircle(size: 36),
                  SizedBox(width: 10),
                  Expanded(child: AppSkeletonBox(height: 14)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
