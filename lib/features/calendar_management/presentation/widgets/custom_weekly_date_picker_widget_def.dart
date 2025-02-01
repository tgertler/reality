import 'package:flutter/material.dart';

class CustomWeeklyDatePicker extends StatefulWidget {
  CustomWeeklyDatePicker({
    Key? key,
    required this.selectedDay,
    required this.changeDay,
    this.weekdayText = 'Week',
    this.weekdays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    this.backgroundColor = const Color(0xFFFAFAFA),
    this.selectedDigitBackgroundColor = const Color(0xFF2A2859),
    this.selectedDigitBorderColor = const Color(0x00000000), // Transparent color
    this.selectedDigitColor = const Color(0xFFFFFFFF),
    this.digitsColor = const Color(0xFF000000),
    this.weekdayTextColor = const Color(0xFF303030),
    this.enableWeeknumberText = true,
    this.weeknumberColor = const Color(0xFFB2F5FE),
    this.weeknumberTextColor = const Color(0xFF000000),
    this.daysInWeek = 7,
    this.controller,
  })  : assert(weekdays.length == daysInWeek, "weekdays must be of length $daysInWeek"),
        super(key: key);

  final DateTime selectedDay;
  final Function(DateTime) changeDay;
  final String weekdayText;
  final List<String> weekdays;
  final Color backgroundColor;
  final Color selectedDigitBackgroundColor;
  final Color selectedDigitBorderColor;
  final Color selectedDigitColor;
  final Color digitsColor;
  final Color weekdayTextColor;
  final bool enableWeeknumberText;
  final Color weeknumberColor;
  final Color weeknumberTextColor;
  final int daysInWeek;
  final PageController? controller;

  @override
  _CustomWeeklyDatePickerState createState() => _CustomWeeklyDatePickerState();
}

class _CustomWeeklyDatePickerState extends State<CustomWeeklyDatePicker> {
  late PageController _controller;
  late DateTime _initialSelectedDay;
  late int _weeknumberInSwipe;
  final int _weekIndexOffset = 1000;
  final DateTime _todaysDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? PageController(initialPage: _weekIndexOffset);
    _initialSelectedDay = widget.selectedDay;
    _weeknumberInSwipe = widget.selectedDay.weekOfYear;
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: widget.backgroundColor,
      child: Row(
        children: <Widget>[
          widget.enableWeeknumberText
              ? Container(
                  padding: EdgeInsets.all(8.0),
                  color: widget.weeknumberColor,
                  child: Text(
                    '${widget.weekdayText} $_weeknumberInSwipe',
                    style: TextStyle(color: widget.weeknumberTextColor),
                  ),
                )
              : Container(),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (int index) {
                setState(() {
                  _weeknumberInSwipe = _initialSelectedDay
                      .addDays(7 * (index - _weekIndexOffset))
                      .weekOfYear;
                  DateTime firstDayOfWeek = _initialSelectedDay
                      .addDays(7 * (index - _weekIndexOffset))
                      .subtract(Duration(days: _initialSelectedDay.weekday - 1));
                  widget.changeDay(firstDayOfWeek);
                });
              },
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, weekIndex) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: _weekdays(weekIndex - _weekIndexOffset),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _weekdays(int weekIndex) {
    List<Widget> weekdays = [];
    for (int i = 0; i < widget.daysInWeek; i++) {
      final int offset = i + 1 - _initialSelectedDay.weekday;
      final int daysToAdd = weekIndex * widget.daysInWeek + offset;
      final DateTime dateTime = _initialSelectedDay.addDays(daysToAdd);
      weekdays.add(_dateButton(dateTime));
    }
    return weekdays;
  }

  Widget _dateButton(DateTime dateTime) {
    final String weekday = widget.weekdays[dateTime.weekday - 1];
    final bool isSelected = dateTime.isSameDateAs(widget.selectedDay);
    final bool isTodaysDate = dateTime.isSameDateAs(_todaysDateTime);

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.changeDay(dateTime),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Text(
                  '$weekday',
                  style: TextStyle(fontSize: 12.0, color: widget.weekdayTextColor),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(1.0),
                decoration: BoxDecoration(
                    color: isTodaysDate ? widget.selectedDigitBorderColor : Colors.transparent,
                    shape: BoxShape.circle),
                child: CircleAvatar(
                  backgroundColor: isSelected ? widget.selectedDigitBackgroundColor : widget.backgroundColor,
                  radius: 14.0,
                  child: Text(
                    '${dateTime.day}',
                    style: TextStyle(
                        fontSize: 16.0,
                        color: isSelected ? widget.selectedDigitColor : widget.digitsColor),
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

extension DateTimeExtension on DateTime {
  bool isSameDateAs(DateTime other) {
    return this.year == other.year && this.month == other.month && this.day == other.day;
  }

  DateTime addDays(int days) {
    return this.add(Duration(days: days));
  }

  int get weekOfYear {
    final firstDayOfYear = DateTime(this.year, 1, 1);
    final daysSinceFirstDay = this.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil();
  }
}