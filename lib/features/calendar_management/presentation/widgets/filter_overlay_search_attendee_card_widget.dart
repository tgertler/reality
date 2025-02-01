import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/filter_active_provider.dart';

class FilterOverlaySearchAttendeeCard extends ConsumerWidget {
  final String title; // Name des Attendees
  final String id; // ID des Attendees
  final bool isToggled; // Zustand der Toggle-Bar

  const FilterOverlaySearchAttendeeCard({
    Key? key,
    required this.title,
    required this.id,
    required this.isToggled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
      child: Container(
        color: Colors.red,
        width: double.infinity,
        height: 60,
        child: Row(
          children: [
            Container(
              height: double.infinity,
              width: 6,
              color: const Color.fromARGB(255, 105, 105, 105),
            ),
            SizedBox(
              width: 60,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                ),
                child: Center(
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
              ),
            ),
            Expanded(
              child: Container(
                color: const Color.fromARGB(255, 26, 26, 26),
                padding: const EdgeInsets.only(left: 10.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: TextStyle(color: Colors.white, fontSize: 17),
                          ),
                          Text(
                            "Teilnehmer",
                            style:
                                TextStyle(color: Colors.white30, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Switch(
                        value: isToggled,
                        onChanged: (bool value) {
                          if (value) {
                            ref
                                .read(activeFiltersProvider.notifier)
                                .addAttendee(id, title);
                          } else {
                            ref
                                .read(activeFiltersProvider.notifier)
                                .removeAttendee(id);
                          }
                        },
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.white30,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
