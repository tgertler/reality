import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/show_management/show_discovery/presentation/providers/search_provider.dart';
import 'package:go_router/go_router.dart';

class MainSearchBarWidget extends ConsumerStatefulWidget {
  const MainSearchBarWidget({Key? key}) : super(key: key);

  @override
  _MainSearchBarWidgetState createState() => _MainSearchBarWidgetState();
}

class _MainSearchBarWidgetState extends ConsumerState<MainSearchBarWidget> {
  late TextEditingController textFieldController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    textFieldController = TextEditingController();
  }

  @override
  void dispose() {
    textFieldController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchNotifierProvider.notifier).search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: TextField(
        autofocus: true,
        controller: textFieldController,
        onChanged: (value) => _onSearchChanged(value),
        onTap: () => {
          /* ref.read(mainSearchOverlayProvider.notifier).showOverlay(), */
        },
        decoration: InputDecoration(
          hintText: 'Suchen',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(0),
            borderSide: BorderSide(
              width: 0,
              style: BorderStyle.none,
            ),
          ),
          prefixIcon: Icon(Icons.search),
          suffixIcon: Padding(
            padding: EdgeInsets.only(right: 10),
            child: SizedBox(
              height: 30.0,
              width: 30.0,
              child: GestureDetector(
                onTap: () {
/*                   ref.read(mainSearchOverlayProvider.notifier).hideOverlay(); */
                  ref.read(searchNotifierProvider.notifier).clearSearch();
                  context.pop();
                  /* textFieldController.clear(); */
                },
                child: Icon(Icons.close, color: Colors.white),
              ),
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
          contentPadding: EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }
}
