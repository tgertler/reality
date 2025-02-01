/*This widget contains a card for a show plus the underlining title. The card should like the search result cards from Pocket Casts.*/

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/utils/router.dart';

class MainSearchShowCard extends StatelessWidget {
  final String title; // Titel der Show
  final String id; // Titel der Show

  const MainSearchShowCard({Key? key, required this.title, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('${AppRoutes.mainSearch}${AppRoutes.showOverview}/$id');
      },
      child: Padding(
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
                      child: Icon(Icons.tv, size: 40, color: Colors.grey[400])),
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
                              "Show",
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
      ),
    );
  }
}
