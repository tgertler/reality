import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/widgets/newsticker_widget.dart';
import 'package:frontend/features/news_ticker/presentation/providers/news_ticker_provider.dart';

import '../../features/show_management/show_discovery/presentation/widgets/search_bar_widget_nofunctionality.dart';

class TopBarWidget extends ConsumerWidget implements PreferredSizeWidget {
  const TopBarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsItems = ref.watch(newsTickerHeadlinesProvider);

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      //backgroundColor: const Color.fromARGB(255, 213, 245, 245),
      backgroundColor: Colors.white,
      //backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      flexibleSpace: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          NewsTicker.fromAsyncValue(
            newsItems,
          ),
          MainSearchBarWidgetNofunctionality(),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(90);
}
