/* This page contains an overlay page that opens after the user uses the search bar. 
Two sections are then shown as the columns. One for the show and one for the attendees.*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/widgets/loading/app_skeleton.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/filter_overlay_search_attendee_card_widget.dart';
import 'package:frontend/features/calendar_management/presentation/widgets/filter_overlay_search_show_card_widget.dart';
import '../providers/filter_active_provider.dart';
import '../providers/search_provider.dart';

class FilterOverlaySearchContentWidget extends ConsumerWidget {
  const FilterOverlaySearchContentWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchNotifierProvider);
    final activeFiltersState = ref.watch(activeFiltersProvider);

    return Container(
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
              child: const _FilterSearchSkeleton(),
            ),
          if (searchState.errorMessage.isNotEmpty)
            Center(
                child: Text(searchState.errorMessage,
                    style: TextStyle(color: Colors.red))),
          if (!searchState.isLoading)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: searchState.results.length,
                  itemBuilder: (context, index) {
                    final result = searchState.results[index];
                    if (result['type'] == 'show') {
                      final isToggled = activeFiltersState.activeShows
                          .any((show) => show.showId == result['data'].id);

                      return FilterOverlaySearchShowCard(
                        id: result['data'].id,
                        title: result['data'].displayTitle,
                        genre: result['data'].genre,
                        isToggled: isToggled,
                      );
                    }
                    if (result['type'] == 'attendee') {
                      final isToggled = activeFiltersState.activeAttendees
                          .any((attendee) => attendee.id == result['data'].id);

                      return FilterOverlaySearchAttendeeCard(
                        id: result['data'].id,
                        title: result['data'].name,
                        isToggled: isToggled,
                      );
                    }
                    return SizedBox
                        .shrink(); // Return an empty widget if the type is neither 'show' nor 'attendee'
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterSearchSkeleton extends StatelessWidget {
  const _FilterSearchSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: List.generate(
          5,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                AppSkeletonBox(width: 42, height: 42, borderRadius: BorderRadius.all(Radius.circular(8))),
                SizedBox(width: 10),
                Expanded(child: AppSkeletonLines(lines: 2, height: 11, widths: [0.65, 0.35])),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
