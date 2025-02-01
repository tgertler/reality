import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/filter_overlay_content_widget.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/filter_overlay_search_bar_widget_nofunctionality.dart';

class FilterOverlayWidget extends ConsumerWidget {
  final VoidCallback onClose;

  const FilterOverlayWidget({Key? key, required this.onClose})
      : super(key: key);

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
                    child: FilterOverlaySearchBarWidgetNoFunctionality()),

              ],
            ),
          ),
          Expanded(
              child: FilterOverlayContentWidget()),
        ],
      ),
    );
  }
}
