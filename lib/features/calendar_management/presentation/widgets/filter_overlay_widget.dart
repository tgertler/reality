import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/filter_overlay_content_widget.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/filter_overlay_search_bar_widget_nofunctionality.dart';

class FilterOverlayWidget extends ConsumerWidget {
  final VoidCallback onClose;

  const FilterOverlayWidget({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Container(
      color: Colors.black,
      height: double.infinity,
      child: Column(
        children: [
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
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
