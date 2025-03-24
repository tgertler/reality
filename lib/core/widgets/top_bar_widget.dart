import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/newsticker_widget.dart';

import '../../features/show_management/show_discovery/presentation/widgets/search_bar_widget_nofunctionality.dart';

class TopBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const TopBarWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      //backgroundColor: const Color.fromARGB(255, 213, 245, 245),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      //backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      flexibleSpace: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          NewsTicker(
            // NewsTicker is a custom widget
            newsItems: [
              'Neue Staffel von "Big Brother" startet nächste Woche!',
              '"Deutschland sucht den Superstar" feiert Jubiläum!',
              'Spannung pur: Finale von "The Voice of Germany" steht bevor!',
              '"Love Island" sorgt für heiße Flirts und Dramen!',
              '"Das Dschungelcamp" kehrt mit neuen Promis zurück!',
              '"Germany Next Topmodel" sucht wieder die Schönste im Land!',
              '"Promi Big Brother" enthüllt die Geheimnisse der Stars!',
              '"Bauer sucht Frau" bringt Herzen zusammen!',
              '"Die Bachelorette" verteilt ihre letzten Rosen!',
              '"Temptation Island" stellt Beziehungen auf die Probe!'
            ],
          ),
          MainSearchBarWidgetNofunctionality(),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(110);
}
