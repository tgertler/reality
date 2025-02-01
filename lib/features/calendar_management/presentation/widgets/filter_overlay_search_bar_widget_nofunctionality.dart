import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/filter_overlay_search_provider.dart';

class FilterOverlaySearchBarWidgetNoFunctionality extends ConsumerWidget {
  const FilterOverlaySearchBarWidgetNoFunctionality({Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var textFieldController = TextEditingController();
    final isFilterOverlayVisible = ref.watch(filterOverlaySearchProvider);

    return Container(
      child: TextField(
        readOnly: true,
        controller: textFieldController,
        onTap: () => {
          ref.read(filterOverlaySearchProvider.notifier).state =
              !isFilterOverlayVisible
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
