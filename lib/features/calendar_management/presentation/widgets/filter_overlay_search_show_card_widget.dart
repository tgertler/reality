/*This widget contains a card for a show plus the underlining title. The card should like the search result cards from Pocket Casts.*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/filter_active_provider.dart';

class FilterOverlaySearchShowCard extends ConsumerWidget {
  final String title; // Titel der Show
  final String id; // Titel der Show
  final bool isToggled; // Zustand der Toggle-Bar

  const FilterOverlaySearchShowCard(
      {super.key,
      required this.title,
      required this.id,
      required this.isToggled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
      child: Container(
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
                    child: Icon(Icons.tv, size: 40, color: Colors.white)),
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
                            style: TextStyle(color: Colors.white, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "Show",
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
                                .addShow(id, title);
                          } else {
                            ref
                                .read(activeFiltersProvider.notifier)
                                .removeShow(id);
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
