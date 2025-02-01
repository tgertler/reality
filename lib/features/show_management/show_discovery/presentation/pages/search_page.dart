/* This page contains an overlay page that opens after the user uses the search bar. 
Two sections are then shown as the columns. One for the show and one for the attendees.*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/show_management/show_discovery/presentation/providers/search_provider.dart';
import 'package:frontend/features/show_management/show_discovery/presentation/widgets/search_show_card_widget.dart';

import '../widgets/search_attendee_card_widget.dart';
import '../widgets/search_bar_widget.dart';

class MainSearchOverlay extends ConsumerWidget {
  const MainSearchOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 213, 245, 245),
        toolbarHeight: 98,
        title: Padding(
          padding: const EdgeInsets.only(top: 50),
          child: MainSearchBarWidget(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.black),
        child: Column(
          children: [
            Container(
              height: 1,
              width: double.infinity,
              color: const Color.fromARGB(255, 17, 17, 17),
            ),
            if (searchState.isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: const Center(child: CircularProgressIndicator()),
              ),
            if (searchState.errorMessage.isNotEmpty)
              Center(
                  child: Text(searchState.errorMessage,
                      style: TextStyle(color: Colors.red))),
            if (!searchState.isLoading)
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: searchState.results.length,
                  itemBuilder: (context, index) {
                    final result = searchState.results[index];
                    if (result['type'] == 'show') {
                      return MainSearchShowCard(
                        id: result['data'].id,
                        title: result['data'].title,
                      );
                    }
                    if (result['type'] == 'attendee') {
                      return MainSearchAttendeeCard(
                        title: result['data'].name,
                      );
                    }
                    return SizedBox
                        .shrink(); // Return an empty widget if the type is neither 'show' nor 'attendee'
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
