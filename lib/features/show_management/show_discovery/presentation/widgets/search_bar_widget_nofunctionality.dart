import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/utils/router.dart';

class MainSearchBarWidgetNofunctionality extends ConsumerWidget {
  const MainSearchBarWidgetNofunctionality({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var textFieldController = TextEditingController();

    return Container(
      margin: EdgeInsets.zero, // Entfernt jeglichen Rand
      padding: EdgeInsets.zero, // Entfernt jegliches Padding
      child: TextField(
        readOnly: true,
        controller: textFieldController,
        onTap: () => {
          /* ref.read(mainSearchOverlayProvider.notifier).showOverlay(), */
          context.push(AppRoutes.mainSearch),
        },
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(0),
            borderSide: BorderSide(
              width: 0,
              style: BorderStyle.none,
            ),
          ),
          hintText: 'Suchen',
          prefixIcon: Icon(Icons.search),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(right: 10),
                child: SizedBox(
                  height: 30.0,
                  width: 30.0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 5.0),
                child: IconButton(
                  iconSize: 28,
                  icon: Icon(Icons.account_circle),
                  color: Colors.white,
                  onPressed: () {
                    // Hier kannst du die Navigation oder andere Aktionen hinzufügen
                    context.push(AppRoutes.user);
                  },
                ),
              ),
            ],
          ),
          fillColor: const Color(0xFF121212),
          filled: true,
          //contentPadding: EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }
}
