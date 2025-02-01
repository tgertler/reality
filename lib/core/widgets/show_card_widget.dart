import 'package:flutter/material.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:go_router/go_router.dart';

class ShowCardWidget extends StatelessWidget {
final String showId;
final String pageContext;

const ShowCardWidget({ Key? key, required this.showId, required this.pageContext }) : super(key: key);

  @override
  Widget build(BuildContext context){
    return GestureDetector(
      onTap: () {
        if (pageContext == 'home') {
        context.go('${AppRoutes.home}${AppRoutes.showOverview}/3');
        } else if (pageContext == 'calendar') {
        context.go('${AppRoutes.calendar}${AppRoutes.showOverview}/3');
        }
      },
      child: Container(
        width: double.infinity,
        height: 50,
        color: const Color.fromARGB(255, 30, 30, 30),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                color: const Color.fromARGB(255, 248, 144, 231),
              ),
            ),
            Flexible(
              flex: 10,
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.only(right: 0.0, left: 10.0),
                  child: Text('20:30'),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                child: Icon(Icons.fiber_manual_record,
                    size: 5, color: const Color.fromARGB(255, 248, 144, 231)),
              ),
            ),
            Expanded(
              flex: 24,
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.only(left: 0.0),
                  child: Text('Sommerhaus der Stars'),
                ),
              ),
            ),
            Expanded(
              flex: 14,
              child: Container(
                child: Icon(Icons.tv_off_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}