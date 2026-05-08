import 'package:flutter/material.dart';
import 'package:frontend/features/feed_management/data/models/feed_item.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/bingo_emotions_per_show_block_feed_card.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/bingo_feature_promo_feed_card.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/coming_this_week_block_feed_card.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/featured_show_block_feed_card.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/latest_releases_block_feed_card.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/monthly_overview_block_feed_card.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/next_3_premieres_block_feed_card.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/next_big_premiere_feed_card.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/next_month_preview_block_feed_card.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/random_show_feed_card.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/quote_of_week_feed_card.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/season_finale_feed_card.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/today_shows_block_feed_card.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/throwback_feed_card.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/trash_events_block_feed_card.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/trending_shows_block_feed_card.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/show_tiktok_hashtags_block_feed_card.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/generic_feed_card.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/generic_bingo_stats_block_feed_card.dart';
import 'package:frontend/features/feed_management/presentation/widgets/cards/bingo_field_heatmap_block_feed_card.dart';
import 'package:frontend/features/feed_management/presentation/widgets/feed_card_share_wrapper.dart';

class FeedItemRenderer extends StatelessWidget {
  final FeedItem feedItem;

  const FeedItemRenderer({super.key, required this.feedItem});

  @override
  Widget build(BuildContext context) {
    final type = feedItem.itemType.toLowerCase().replaceAll('-', '_');

    final Widget card;
    switch (type) {
      case 'next_big_premiere_item':
        card = NextBigPremiereFeedCard(item: feedItem);
      case 'season_finale_item':
        card = SeasonFinaleFeedCard(item: feedItem);
      case 'next_month_preview_block':
        card = NextMonthPreviewBlockFeedCard(item: feedItem);
      case 'almost_complete_season_item':
        card = GenericFeedCard(item: feedItem);
      case 'bingo_promo':
      case 'bingo_promotion':
      case 'bingo_feature':
      case 'bingo_feature_promo':
      case 'bingo_feature_card':
        card = BingoFeaturePromoFeedCard(item: feedItem);
      case 'monthly_overview_block':
        card = MonthlyOverviewBlockFeedCard(item: feedItem);
      case 'today_shows_block':
        card = TodayShowsBlockFeedCard(item: feedItem);
      case 'coming_this_week_block':
        card = ComingThisWeekBlockFeedCard(item: feedItem);
      case 'next_3_premieres_block':
        card = Next3PremieresBlockFeedCard(item: feedItem);
      case 'low_today_activity_item':
        card = GenericFeedCard(item: feedItem);
      case 'random_show':
      case 'random_show_block':
        card = RandomShowFeedCard(item: feedItem);
      case 'featured_show_block':
        card = FeaturedShowBlockFeedCard(item: feedItem);
      case 'latest_releases_block':
        card = LatestReleasesBlockFeedCard(item: feedItem);
      case 'quote_of_the_week':
      case 'quote_of_week':
        card = QuoteOfWeekFeedCard(item: feedItem);
      case 'throwback_moment':
      case 'throwback_of_week':
      case 'throwback':
        card = ThrowbackFeedCard(item: feedItem);
      case 'generic_bingo_stats_block':
      case 'bingo_stats_block':
        card = GenericBingoStatsBlockFeedCard(item: feedItem);
      case 'bingo_field_heatmap_block':
        card = BingoFieldHeatmapBlockFeedCard(item: feedItem);
      case 'trending_shows_block':
        card = TrendingShowsBlockFeedCard(item: feedItem);
      case 'show_tiktok_hashtags_block':
        card = ShowTiktokHashtagsBlockFeedCard(item: feedItem);
      case 'trash_events_block':
        card = TrashEventsBlockFeedCard(item: feedItem);
      case 'bingo_emotions_per_show_block':
        card = BingoEmotionsPerShowBlockFeedCard(item: feedItem);
      default:
        card = GenericFeedCard(item: feedItem);
    }

    return FeedCardShareWrapper(child: card);
  }
}
