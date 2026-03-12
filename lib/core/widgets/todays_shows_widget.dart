import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/core/utils/streaming_service_logo.dart';
import 'package:intl/intl.dart';
import 'package:frontend/features/calendar_management/domain/entities/calendar_event_with_show.dart';

class TodayShowsWidget extends StatelessWidget {
  final List<CalendarEventWithShow> events;

  const TodayShowsWidget({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Container(
          padding: const EdgeInsets.only(bottom: 1.0),
          height: 40,
          child: Row(
            children: [
              /* Flexible(
                flex: 4,
                child: Center(
                  child: Text(
                    DateFormat('HH:mm')
                        .format(event.calendarEvent.startDatetime.toLocal()),
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ), */
              Expanded(
                child: Container(
                  child: Icon(
                    Icons.fiber_manual_record,
                    size: 5,
                    color: const Color.fromARGB(255, 213, 245, 245),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 20,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    event.show.title ?? 'Unknown Title',
                    style: TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              Flexible(
                flex: 4,
                child: SvgPicture.asset(
                  getStreamingServiceLogo(
                      event.season.streamingOption ?? 'default'),
                  allowDrawingOutsideViewBox: true,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
