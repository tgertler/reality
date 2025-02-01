import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../../core/utils/logger.dart';

class DatepickerState {
  final DateTime selectedDate;

  final Logger _logger = getLogger('DatepickerProvider');

  DatepickerState({
    required this.selectedDate,
  });

  DatepickerState copyWith({
    DateTime? selectedDate,
  }) {
    return DatepickerState(
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

class DatepickerNotifier extends StateNotifier<DatepickerState> {
  DatepickerNotifier() : super(DatepickerState(selectedDate: DateTime.now()));
  
  static DateTime _getStartOfWeek(DateTime date) {
    int dayOfWeek = date.weekday;
    return date.subtract(Duration(days: dayOfWeek - 1));
  }

  void changeDate(DateTime value) {
    state = state.copyWith(selectedDate: value);
    state._logger.i('Selected date changed to: ${state.selectedDate}');
  }

  void previousWeek() {
    DateTime newDate = state.selectedDate.subtract(Duration(days: 7));
    state = DatepickerState(selectedDate: _getStartOfWeek(newDate));
  }

  void nextWeek() {
    DateTime newDate = state.selectedDate.add(Duration(days: 7));
    state = DatepickerState(selectedDate: _getStartOfWeek(newDate));
  }
}

/// Riverpod Provider für den `SearchNotifier`
final datepickerNotifierProvider =
    StateNotifierProvider<DatepickerNotifier, DatepickerState>((ref) {
  return DatepickerNotifier();
});
