import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/home_streaming_content_widget.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/top_bar_widget.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopBarWidget(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _onTabTapped(0),
                  child: Text(
                    'Streaming',
                    style: TextStyle(
                      fontWeight: _selectedIndex == 0
                          ? FontWeight.w900
                          : FontWeight.w900,
                      color: _selectedIndex == 0
                          ? Colors.white
                          : const Color.fromARGB(88, 255, 255, 255),
                      fontSize: 23,
                      fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _onTabTapped(1),
                  child: Text(
                    'TV',
                    style: TextStyle(
                      fontWeight: _selectedIndex == 1
                          ? FontWeight.w900
                          : FontWeight.w900,
                      color: _selectedIndex == 1
                          ? Colors.white
                          : const Color.fromARGB(88, 255, 255, 255),
                      fontSize: 23,
                      fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: _selectedIndex == 0
                ? HomeStreamingContentWidget()
                : Center(child: Text('TV Content')),
          ),
        ],
      ),
    );
  }
}
