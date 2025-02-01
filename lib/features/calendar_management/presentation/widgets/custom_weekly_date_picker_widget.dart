import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/custom_weekly_date_picker_widget_def.dart';

import '../providers/datepicker_provider.dart';
import '../providers/filter_overlay_provider.dart';

class CustomWeeklyDatePickerWidget extends ConsumerWidget {
  const CustomWeeklyDatePickerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datepickerState = ref.watch(datepickerNotifierProvider);
    final PageController pageController = PageController(initialPage: 1000);
    final isFilterOverlayVisible = ref.watch(filterOverlayProvider);

    return IgnorePointer(
      ignoring: isFilterOverlayVisible,
      child: Opacity(
        opacity: isFilterOverlayVisible ? 0.3 : 1.0,
        child: CustomWeeklyDatePicker(
          controller: pageController,
          enableWeeknumberText: false,
          weeknumberColor: Colors.white,
          weeknumberTextColor: Colors.white,
          backgroundColor: Colors.transparent,
          weekdayTextColor: const Color(0xFF8A8A8A),
          digitsColor: Colors.white,
          selectedDigitBackgroundColor: const Color.fromARGB(255, 248, 144, 231),
          selectedDay: datepickerState.selectedDate,
          changeDay: (value) =>
              ref.read(datepickerNotifierProvider.notifier).changeDate(value),
          weekdays: const ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"],
        ),
      ),
    );
  }
}
