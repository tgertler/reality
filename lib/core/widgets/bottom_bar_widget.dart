import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../features/show_management/show_discovery/presentation/pages/search_page.dart';
import '../../features/show_management/show_discovery/presentation/providers/search_overlay_provider.dart';

class AppView extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const AppView({super.key, required this.navigationShell});

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOverlayVisible = ref.watch(mainSearchOverlayProvider);

    return Scaffold(
      body: Stack(
        children: [
          navigationShell,
          if (isOverlayVisible) MainSearchOverlay(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 0,
        backgroundColor: const Color(0xFF121212),
/*         backgroundColor: Colors.black, */
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: navigationShell.currentIndex,
        onTap: _goBranch,
        items: [
          _menuItem(
            context,
            index: 0,
            currentIndex: navigationShell.currentIndex,
            icon: Icons.home,
          ),
          _menuItem(
            context,
            index: 1,
            currentIndex: navigationShell.currentIndex,
            icon: Icons.calendar_month,
          ),
/*           _menuItem(
            context,
            index: 2,
            currentIndex: navigationShell.currentIndex,
            icon: Icons.star,
<<<<<<< HEAD
          ), */
=======
          ),
>>>>>>> 2275eb12469187351262114ef8e8ec75d1ca9801
        ],
      ),
    );
  }

  BottomNavigationBarItem _menuItem(
    BuildContext context, {
    required int index,
    required int currentIndex,
    required IconData icon,
  }) {
    return BottomNavigationBarItem(
      icon: Stack(
        alignment: Alignment.center,
        children: [
          if (currentIndex == index)
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: SizedBox(
                height: 50.0,
                width: 50.0,
                child: SvgPicture.asset(
                  'stroke2.svg', // Pfad zu Ihrem SVG
                  color: const Color.fromARGB(255, 248, 144, 231),
                  allowDrawingOutsideViewBox: true,
                ),
              ),
            ),
          Icon(
            icon,
            color: currentIndex == index
                ? Colors.white // Kräftige Farbe für das ausgewählte Icon
                : const Color.fromARGB(151, 255, 255,
                    255), // Kontrastreiche Farbe für nicht ausgewählte Icons
          ),
        ],
      ),
      label: '',
    );
  }
}
