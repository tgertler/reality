import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class NewsTicker extends StatelessWidget {
  final List<String> newsItems;

  const NewsTicker({Key? key, required this.newsItems}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 25,
      child: Marquee(
        text: newsItems.join('   •   '),
        style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0), fontSize: 12),
        scrollAxis: Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.start,
        blankSpace: 20.0,
        velocity: 30.0,
        pauseAfterRound: Duration(seconds: 1),
        startPadding: 10.0,
        accelerationDuration: Duration(seconds: 1),
        accelerationCurve: Curves.linear,
        decelerationDuration: Duration(milliseconds: 500),
        decelerationCurve: Curves.easeOut,
      ),
    );
  }
}