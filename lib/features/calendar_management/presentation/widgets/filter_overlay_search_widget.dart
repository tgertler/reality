import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/filter_overlay_search_bar_widget.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/filter_overlay_search_content_widget.dart';


class FilterOverlaySearchWidget extends ConsumerWidget {
  final VoidCallback onClose;

  const FilterOverlaySearchWidget({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Container(
      color: Colors.black,
      height: double.infinity,
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: Row(
              children: [
                Expanded(
                    flex: 9,
                    child: FilterOverlaySearchBarWidget()),
                Expanded(
                  flex: 1,
                  child: IconButton(
                    onPressed: onClose,
                    icon: Icon(Icons.close),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
              child: FilterOverlaySearchContentWidget()),
        ],
      ),
    );
  }
}
