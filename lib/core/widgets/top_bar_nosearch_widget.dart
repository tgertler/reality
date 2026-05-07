import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_colors.dart';

class TopBarNoSearchWidget extends StatelessWidget implements PreferredSizeWidget {
  const TopBarNoSearchWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      backgroundColor: AppColors.pop,
      toolbarHeight: 50,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(50);
}