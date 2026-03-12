import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/core/utils/streaming_service_logo.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class CalendarEventCardWidget extends StatelessWidget {
  final String calendarEventId;
  final DateTime startDatetime;
  final DateTime endDatetime;
  final String showName;
  final String showId;
  final String streamingService; // Hinzugefügt

  const CalendarEventCardWidget({
    super.key,
    required this.calendarEventId,
    required this.startDatetime,
    required this.endDatetime,
    required this.showName,
    required this.showId,
    required this.streamingService, // Hinzugefügt
  });
<<<<<<< HEAD
=======

  String _getStreamingServiceLogo(String service) {
    switch (service.toLowerCase()) {
      case 'netflix':
        return 'logos/netflix.svg';
      case 'rtl+':
        return 'logos/rtl+.svg';
      case 'prime':
        return 'logos/prime.svg';
      case 'joyn':
        return 'logos/joyn.svg';
      // Weitere Streaming-Dienste hier hinzufügen
      default:
        return 'logos/default.svg'; // Standard-Logo
    }
  }
>>>>>>> 2275eb12469187351262114ef8e8ec75d1ca9801

  @override
  Widget build(BuildContext context) {
    //final startTime = DateFormat('HH:mm').format(startDatetime);
    final duration = endDatetime.difference(startDatetime).inMinutes;

    return GestureDetector(
      onTap: () {
        context.push('${AppRoutes.showOverview}/$showId');
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
/*             Flexible(
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
            ),*/
            Expanded(
              flex: 24,
              child: Container(
                child: Padding(
<<<<<<< HEAD
                  padding: const EdgeInsets.only(left: 20.0),
=======
                  padding: const EdgeInsets.only(left: 0.0),
>>>>>>> 2275eb12469187351262114ef8e8ec75d1ca9801
                  child: Text(
                    showName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 14,
              child: Padding(
<<<<<<< HEAD
                padding: const EdgeInsets.only(
                    top: 20.0, bottom: 20.0, left: 30, right: 10),
                child: Center(
                  child: SvgPicture.asset(
                    getStreamingServiceLogo(streamingService), // Angepasst
=======
                padding: const EdgeInsets.only(top: 24.0, bottom: 24.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SvgPicture.asset(
                    _getStreamingServiceLogo(streamingService), // Angepasst
>>>>>>> 2275eb12469187351262114ef8e8ec75d1ca9801
                    allowDrawingOutsideViewBox: true,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
