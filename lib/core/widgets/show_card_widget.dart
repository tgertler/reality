import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class ShowCardWidget extends StatelessWidget {
  final String calendarEventId;
  final DateTime startDatetime;
  final DateTime endDatetime;
  final String showName;
  final String showId;

  const ShowCardWidget({
    super.key,
    required this.calendarEventId,
    required this.startDatetime,
    required this.endDatetime,
    required this.showName,
    required this.showId,
  });

  @override
  Widget build(BuildContext context) {
    initializeDateFormatting('de_DE');
    final now = DateTime.now();
    final isLive = now.isAfter(startDatetime) && now.isBefore(endDatetime);
    final duration = endDatetime.difference(startDatetime).inMinutes;
    final isFinished = now.isAfter(endDatetime);


    return GestureDetector(
      onTap: () {
        context.go('${AppRoutes.calendar}${AppRoutes.showOverview}/$showId');
      },
      child: Container(
        width: double.infinity,
        height: 60,
        color: const Color.fromARGB(255, 30, 30, 30),
        child: Stack(
          children: [
            Row(
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
                            DateFormat('HH:mm', 'de_DE').format(startDatetime),
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
              ],
            ),
            if (isLive)
              Positioned(
                top: 5,
                right: 5,
                child: LiveIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

class LiveIndicator extends StatefulWidget {
  @override
  _LiveIndicatorState createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<LiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}