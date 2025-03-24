import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/search_provider.dart';

class FilterOverlaySearchBarWidget extends ConsumerStatefulWidget {
  const FilterOverlaySearchBarWidget({super.key});

  @override
  _FilterOverlaySearchBarWidgetState createState() =>
      _FilterOverlaySearchBarWidgetState();
}

class _FilterOverlaySearchBarWidgetState
    extends ConsumerState<FilterOverlaySearchBarWidget> {
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
          fillColor: Colors.black,
          filled: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }
}
