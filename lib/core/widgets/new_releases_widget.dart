import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/utils/streaming_service_logo.dart';
import 'package:frontend/features/calendar_management/domain/entities/calendar_event_with_show.dart';

class NewReleasesWidget extends StatelessWidget {
  final List<CalendarEventWithShow> events;
  final PageController pageController;

  const NewReleasesWidget({
    super.key,
    required this.events,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      padEnds: false,
      controller: pageController,
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];

        return Column(
          children: [
            Expanded(
              child: Card(
                color: const Color.fromARGB(255, 43, 43, 43),
                child: Column(
                  children: [
                    Container(
                      width: 160,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 168, 232, 255),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                      ),
                    ),
                    Container(
                      width: 160,
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            event.show.title ?? 'Unknown Title',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Text(
<<<<<<< HEAD
                            DateFormat('dd.MM.yyyy').format(
=======
                            DateFormat('dd.MM.yyyy, HH:mm').format(
>>>>>>> 2275eb12469187351262114ef8e8ec75d1ca9801
                                event.calendarEvent.startDatetime.toLocal()),
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 15,
                            width: 50,
<<<<<<< HEAD
                            child: Center(
                              child: SvgPicture.asset(
                                getStreamingServiceLogo(
                                    event.season.streamingOption ??
                                        'default'), // Angepasst
                                allowDrawingOutsideViewBox: true,
                                fit: BoxFit.contain,
                              ),
=======
                            child: SvgPicture.asset(
                              getStreamingServiceLogo(
                                  event.season.streamingOption ?? 'default'),
                              allowDrawingOutsideViewBox: true,
                              fit: BoxFit.contain,
                              alignment: Alignment.centerLeft,
>>>>>>> 2275eb12469187351262114ef8e8ec75d1ca9801
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
