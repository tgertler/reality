import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/filter_overlay_provider.dart';
import '../providers/filter_overlay_search_provider.dart';

class FilterOverlaySearchBarWidgetNoFunctionality extends ConsumerWidget {
  const FilterOverlaySearchBarWidgetNoFunctionality({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      child: TextField(
        readOnly: true,
        onTap: () {
          ref.read(filterOverlayProvider.notifier).state = false;
          ref.read(filterOverlaySearchProvider.notifier).state = true;
        },
        decoration: InputDecoration(
          hintText: 'Suchen',
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(0),
            borderSide: BorderSide(
              width: 0,
              style: BorderStyle.none,
            ),
          ),
          prefixIcon: Icon(Icons.search),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 36, minHeight: 20),
          fillColor: Colors.black,
          filled: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}
