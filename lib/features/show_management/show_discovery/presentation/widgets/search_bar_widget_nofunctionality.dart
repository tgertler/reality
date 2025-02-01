import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/utils/router.dart';

class MainSearchBarWidgetNofunctionality extends ConsumerWidget {
  const MainSearchBarWidgetNofunctionality({Key? key}) : super(key: key);

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
          suffixIcon: Padding(
            padding: EdgeInsets.only(right: 10),
            child: SizedBox(
              height: 30.0,
              width: 30.0,
            ),
            /*             child: IconButton(
              icon: Icon(Icons.close),
              onPressed: () => {
                ref.read(mainSearchOverlayProvider.notifier).hideOverlay(),
                ref.read(searchNotifierProvider.notifier).clearSearch(),
                textFieldController.clear(),
              },
            ), */
          ),
          fillColor: Colors.black,
          filled: true,
          //contentPadding: EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }
}
