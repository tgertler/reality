import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomPageController {
  final PageController controller;

  CustomPageController() : controller = PageController(initialPage: 1000);

  void jumpToToday() {
    final DateTime _todaysDateTime = DateTime.now();
  }
}

final customPageControllerProvider = Provider<CustomPageController>((ref) {
  return CustomPageController();
});

extension DateTimeExtension on DateTime {
  int get weekOfYear {
    final firstDayOfYear = DateTime(year, 1, 1);
    final daysSinceFirstDay = difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil();
  }
}
