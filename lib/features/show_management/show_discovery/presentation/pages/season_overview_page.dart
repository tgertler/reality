import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/show_management/show_discovery/presentation/providers/season_overview_provider.dart';
import '../widgets/show_overview_title_widget.dart';

class SeasonOverviewPage extends ConsumerStatefulWidget {
  final String seasonId;

  const SeasonOverviewPage({super.key, required this.seasonId});

  @override
  _ShowOverviewPageState createState() => _ShowOverviewPageState();
}

class _ShowOverviewPageState extends ConsumerState<SeasonOverviewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(seasonOverviewProvider.notifier).loadSeason(widget.seasonId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final season = ref.watch(seasonOverviewProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
            ShowOverviewTitleWidget(title: season.seasonNumber.toString(), showId: widget.seasonId),
        ],
      ),
    );
  }
}
