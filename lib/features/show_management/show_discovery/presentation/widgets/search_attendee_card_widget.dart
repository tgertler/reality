/*This widget contains a card for a show plus the underlining title. The card should like the search result cards from Pocket Casts.*/

import 'package:flutter/material.dart';

class MainSearchAttendeeCard extends StatelessWidget {
  final String title; // Titel der Show

  const MainSearchAttendeeCard({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Center(
                    child: Icon(Icons.person, size: 40, color: Colors.grey[400])),
              ),
            ),
            Expanded(
              child: Padding(
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
                    Icon(Icons.chevron_right, color: Colors.white),
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
