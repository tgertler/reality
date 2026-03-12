import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/widgets/flexible_title_widget.dart';
import 'package:frontend/core/widgets/home_streaming_content_widget.dart';
import 'package:frontend/core/widgets/messages/trash_calendar_message_widget.dart';
import 'package:frontend/features/user_management/presentation/providers/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:once/once.dart';

import '../widgets/top_bar_widget.dart';
import '../widgets/messages/welcome_message_widget.dart';
import '../widgets/messages/not_logged_in_message_widget.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;
  bool _isVisible = true;

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userNotifierProvider.notifier).loadUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userNotifierProvider);
    return Scaffold(
      appBar: TopBarWidget(),
      body: Column(
        children: [
          FlexibleTitleWidget(
            textParts: [
              FlexibleTitleTextPart(
                text: 'UN',
                color: const Color.fromARGB(255, 248, 196, 239),
                isBold: true,
              ),
              FlexibleTitleTextPart(
                text: 'SCRIPTED',
                color: Colors.white,
                isBold: true,
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
<<<<<<< HEAD
                  /* if (userState.user != null)  */ const WelcomeMessageWidget(),
                  //if (userState.user == null) const NotLoggedInMessageWidget(),
=======
                  if (userState.user != null) const WelcomeMessageWidget(),
                  if (userState.user == null) const NotLoggedInMessageWidget(),
>>>>>>> 2275eb12469187351262114ef8e8ec75d1ca9801
                  OnceWidget.showHourly(
                    "weekWidget",
                    builder: () {
                      return TrashCalendarWidget(
                        onClose: () {
                          setState(() {
                            _isVisible = false;
                          });
                        },
                      );
                    },
                    fallback: () => Container(),
                  ),
                  HomeStreamingContentWidget()
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
