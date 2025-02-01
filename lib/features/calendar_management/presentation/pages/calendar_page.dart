import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/widgets/top_bar_widget.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/calendar_body_widget.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/custom_weekly_date_picker_widget.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/datepicker_topbar_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: TopBarWidget(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Stack(
            children: [
            Container(
                padding: const EdgeInsets.only(top: 40),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 37, 37, 37),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 9,
                      child: Container(
                        color: const Color.fromARGB(255, 44, 44, 44),
                        //color: const Color.fromARGB(29, 248, 144, 231),
                        //color: const Color.fromARGB(174, 7, 103, 103),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: Transform.translate(
                            offset: Offset(0, -16),
                            child: Text(
                              'Mein Trash-Kalender',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                fontFamily:
                                    GoogleFonts.bricolageGrotesque().fontFamily,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Container(),
                    )
                  ],
                )),
          ]),
          Padding(
              padding: const EdgeInsets.only(bottom: 5.0, top: 20),
              child: DatepickerTopbarWidget()),
          Container(
            width: double.infinity,
            color: const Color.fromARGB(255, 32, 32, 32),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: CustomWeeklyDatePickerWidget()),
                ),
              ],
            ),
          ),
          CalendarBodyWidget(),
        ],
      ),
    );
  }
}
