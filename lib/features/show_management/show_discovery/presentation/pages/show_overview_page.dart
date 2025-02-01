import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/show_overview_provider.dart';
import '../widgets/show_overview_season_list_widget.dart';
import '../widgets/show_overview_title_widget.dart';

class ShowOverviewPage extends ConsumerStatefulWidget {
  final String showId;

  const ShowOverviewPage({Key? key, required this.showId}) : super(key: key);

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
      backgroundColor: const Color.fromARGB(255, 37, 37, 37),
      body: Column(
        children: [
          ShowTitleWidget(title: show.title),
          Container(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                  "Das Sommerhaus der Stars – Kampf der Promipaare (kurz SHDS) ist eine ursprünglich aus Israel stammende Reality-Show. In Deutschland wird sie seit 2016 bei RTL ausgestrahlt."),
            ),
          ),
          //CategoryWidget(),
          //SeasonSelectorWidget(),
          Expanded(
            child: SeasonListWidget(),
          ),
        ],
      ),
    );
  }
}
