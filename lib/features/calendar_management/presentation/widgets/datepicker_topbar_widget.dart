import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../providers/datepicker_provider.dart';
import '../providers/filter_overlay_provider.dart';
import '../providers/page_controller.dart';

class DatepickerTopbarWidget extends ConsumerWidget {
  const DatepickerTopbarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datepickerState = ref.watch(datepickerNotifierProvider);
    final isFilterOverlayVisible = ref.watch(filterOverlayProvider);

    initializeDateFormatting('de_DE', null);

    return IgnorePointer(
      ignoring: isFilterOverlayVisible,
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      ref.read(filterOverlayProvider.notifier).state =
                          !isFilterOverlayVisible;
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 3.0),
                          child: Text('Filter'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Opacity(
                  opacity: isFilterOverlayVisible ? 0.3 : 1.0,
                  child: Center(
                    child: Text(DateFormat('MMMM yyyy', 'de_DE')
                        .format(datepickerState.selectedDate)),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child:
                    Container(), /* GestureDetector(
                  onTap: () {
                    ref
                        .read(datepickerNotifierProvider.notifier)
                        .changeDate(DateTime.now());
                    // Hier wird die Methode jumpToToday aufgerufen
                    final customPageController =
                        ref.read(customPageControllerProvider);
                    customPageController.jumpToToday();
                  },
                  child: Center(
                    child: Text(
                      'Heute',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ), */
              ),
            ],
          ),
        ],
      ),
    );
  }
}
