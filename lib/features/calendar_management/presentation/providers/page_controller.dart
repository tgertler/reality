import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomPageController {
  final PageController controller;

  CustomPageController() : controller = PageController(initialPage: 1000);

  void jumpToToday() {
    if (!controller.hasClients) return;
    controller.jumpToPage(1000);
  }
}

class CalendarMonthPageController {
  final PageController controller;

  CalendarMonthPageController() : controller = PageController(initialPage: 500);

  void jumpToToday() {
    if (!controller.hasClients) return;
    controller.jumpToPage(500);
  }
}

class CalendarThreeDayPageController {
  final PageController controller;

  CalendarThreeDayPageController()
      : controller = PageController(initialPage: 500);

  void jumpToToday() {
    if (!controller.hasClients) return;
    controller.jumpToPage(500);
  }
}

final customPageControllerProvider = Provider<CustomPageController>((ref) {
  return CustomPageController();
});

final calendarMonthPageControllerProvider =
    Provider<CalendarMonthPageController>((ref) {
  return CalendarMonthPageController();
});

final calendarThreeDayPageControllerProvider =
    Provider<CalendarThreeDayPageController>((ref) {
  return CalendarThreeDayPageController();
});

extension DateTimeExtension on DateTime {
  int get weekOfYear {
    final firstDayOfYear = DateTime(year, 1, 1);
    final daysSinceFirstDay = difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil();
  }
}
