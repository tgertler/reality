import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class CalendarEventCardWidget extends StatelessWidget {
  final String calendarEventId;
  final DateTime startDatetime;
  final DateTime endDatetime;
  final String showName;
  final String showId;

  const CalendarEventCardWidget({
    Key? key,
    required this.calendarEventId,
    required this.startDatetime,
    required this.endDatetime,
    required this.showName,
    required this.showId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //final startTime = DateFormat('HH:mm').format(startDatetime);
    final duration = endDatetime.difference(startDatetime).inMinutes;

    return GestureDetector(
      onTap: () {
        context.go('${AppRoutes.calendar}${AppRoutes.showOverview}/$showId');
      },
      child: Container(
        width: double.infinity,
        height: 60,
        color: const Color.fromARGB(255, 30, 30, 30),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                color: const Color.fromARGB(255, 213, 245, 245),
              ),
            ),
            Flexible(
              flex: 10,
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${DateFormat('hh:mm', 'de_DE').format(startDatetime)}',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      '$duration min',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color.fromARGB(255, 168, 168, 168),
                        ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                child: Icon(
                  Icons.fiber_manual_record,
                  size: 5,
                  color: const Color.fromARGB(255, 213, 245, 245),
                ),
              ),
            ),
            Expanded(
              flex: 24,
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.only(left: 0.0),
                  child: Text(showName),
                ),
              ),
            ),
            Expanded(
              flex: 14,
              child: SvgPicture.asset(
                  'rtl-seeklogo.svg', // Pfad zu Ihrem SVG
                  allowDrawingOutsideViewBox: true,
                ),
            ),
          ],
        ),
      ),
    );
  }
}
