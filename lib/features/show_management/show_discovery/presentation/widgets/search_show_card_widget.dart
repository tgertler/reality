/*This widget contains a card for a show plus the underlining title. The card should like the search result cards from Pocket Casts.*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:go_router/go_router.dart';

class MainSearchShowCard extends ConsumerWidget {
  final String title; // Titel der Show
  final String id; // Titel der Show

  const MainSearchShowCard({super.key, required this.title, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('${AppRoutes.showOverview}/${id}'),
      child: Padding(
        padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
        child: Container(
<<<<<<< HEAD
=======
          color: Colors.red,
>>>>>>> 2275eb12469187351262114ef8e8ec75d1ca9801
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
                              style:
                                  TextStyle(color: Colors.white, fontSize: 17),
<<<<<<< HEAD
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
=======
>>>>>>> 2275eb12469187351262114ef8e8ec75d1ca9801
                            ),
                            Text(
                              "Show",
                              style: TextStyle(
                                  color: Colors.white30, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
