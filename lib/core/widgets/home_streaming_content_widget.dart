import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/widgets/attendee_card_widget.dart';
import 'package:frontend/core/widgets/show_card_widget.dart';

class HomeStreamingContentWidget extends ConsumerWidget {
  const HomeStreamingContentWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          ShowCardWidget(showId: "3", pageContext: 'home',),
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: AttendeeCardWidget(title: "title"),
          )
        ],
      ),
    );
  }
}
