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
                    Container(
            height: 45,
            width: double.infinity,
            color: const Color.fromARGB(255, 248, 144, 231),
            child: Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'TRASH',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 248, 196, 239),
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        fontFamily: GoogleFonts.oswald().fontFamily,
                      ),
                    ),
                    TextSpan(
                      text: 'CALENDAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        fontFamily: GoogleFonts.oswald().fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
