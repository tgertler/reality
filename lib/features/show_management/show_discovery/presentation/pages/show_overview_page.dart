import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/show_overview_provider.dart';
import '../widgets/show_overview_season_list_widget.dart';
import '../widgets/show_overview_title_widget.dart';

class ShowOverviewPage extends ConsumerStatefulWidget {
  final String showId;

  const ShowOverviewPage({super.key, required this.showId});

  @override
  _ShowOverviewPageState createState() => _ShowOverviewPageState();
}

class _ShowOverviewPageState extends ConsumerState<ShowOverviewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(showOverviewProvider.notifier).loadShow(widget.showId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final show = ref.watch(showOverviewProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          ShowOverviewTitleWidget(title: show.title, showId: widget.showId),
          show.description.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(show.description),
                  ),
                )
              : Container(),
          //CategoryWidget(),
          //SeasonSelectorWidget(),
          Expanded(
            child: SeasonListWidget(showId: widget.showId),
          ),
        ],
      ),
    );
  }
}
