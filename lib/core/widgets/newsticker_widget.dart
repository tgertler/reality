import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marquee/marquee.dart';

class NewsTicker extends StatelessWidget {
  final List<String> newsItems;

  const NewsTicker({super.key, required this.newsItems});

  factory NewsTicker.fromAsyncValue(AsyncValue<List<String>> asyncItems) {
    return NewsTicker(
      newsItems: asyncItems.maybeWhen(
        data: (items) => items,
        orElse: () => const ['Willkommen bei Reality'],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 25,
      child: Marquee(
        text: newsItems.join('   •   '),
        style: TextStyle(
          color: const Color.fromARGB(255, 0, 0, 0),
          fontSize: 12,
        ),
        scrollAxis: Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.start,
        blankSpace: 20.0,
        velocity: 10.0,
        pauseAfterRound: Duration(seconds: 0),
        startPadding: 10.0,
        accelerationDuration: Duration(seconds: 1),
        accelerationCurve: Curves.linear,
        decelerationDuration: Duration(milliseconds: 500),
        decelerationCurve: Curves.easeOut,
      ),
    );
  }
}