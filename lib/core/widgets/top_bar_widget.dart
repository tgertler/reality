import 'package:flutter/material.dart';

import '../../features/show_management/show_discovery/presentation/widgets/search_bar_widget_nofunctionality.dart';

class TopBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const TopBarWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      backgroundColor: const Color.fromARGB(255, 213, 245, 245),
      toolbarHeight: 110,
      title: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Expanded(
          child: MainSearchBarWidgetNofunctionality()
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(98);
}