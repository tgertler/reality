import 'package:flutter/material.dart';

class TopBarNoSearchWidget extends StatelessWidget implements PreferredSizeWidget {
  const TopBarNoSearchWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      backgroundColor: const Color.fromARGB(255, 213, 245, 245),
      toolbarHeight: 60,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(50);
}