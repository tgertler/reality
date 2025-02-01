import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/filter_active_provider.dart';

class FilterOverlayContentWidget extends ConsumerWidget {
  const FilterOverlayContentWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFiltersState = ref.watch(activeFiltersProvider);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.black),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Container(
                    child: Text(
                      "Shows",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 23.0, top: 8.0),
                child: activeFiltersState.activeShows.isEmpty
                    ? Container(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "Kein Filter ausgewählt",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 168, 168, 168),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: activeFiltersState.activeShows.length,
                        itemBuilder: (context, index) {
                          final show = activeFiltersState.activeShows[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 7, 103, 103),
                              borderRadius: BorderRadius.circular(50.0),
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(left: 20.0),
                                      child: Text(
                                        show.title ?? 'No Title',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.white),
                                  onPressed: () {
                                    ref
                                        .read(activeFiltersProvider.notifier)
                                        .removeShow(show.showId);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Container(
                    child: Text(
                      "Teilnehmer",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 23.0, top: 8.0),
                child: activeFiltersState.activeAttendees.isEmpty
                    ? Container(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "Kein Filter ausgewählt",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 168, 168, 168),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: activeFiltersState.activeAttendees.length,
                        itemBuilder: (context, index) {
                          final attendee = activeFiltersState.activeAttendees[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 7, 103, 103),
                              borderRadius: BorderRadius.circular(50.0),
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(left: 20.0),
                                      child: Text(
                                        attendee.name ?? 'No Name',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.white),
                                  onPressed: () {
                                    ref
                                        .read(activeFiltersProvider.notifier)
                                        .removeAttendee(attendee.id);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
