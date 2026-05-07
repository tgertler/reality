/* This page contains an overlay page that opens after the user uses the search bar. 
Two sections are then shown as the columns. One for the show and one for the attendees.*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/widgets/loading/app_skeleton.dart';
import 'package:frontend/features/show_management/show_discovery/domain/entities/creator.dart';
import 'package:frontend/features/show_management/show_discovery/presentation/providers/search_provider.dart';
import 'package:frontend/features/show_management/show_discovery/presentation/widgets/search_creator_card_widget.dart';
import 'package:frontend/features/show_management/show_discovery/presentation/widgets/search_show_card_widget.dart';

import '../widgets/search_attendee_card_widget.dart';
import '../widgets/search_bar_widget.dart';

class MainSearchOverlay extends ConsumerWidget {
  const MainSearchOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchState = ref.watch(searchNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        toolbarHeight: 98,
        title: Padding(
          padding: const EdgeInsets.only(top: 50),
          child: MainSearchBarWidget(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Container(
          decoration: BoxDecoration(color: const Color(0xFF121212)),
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
                  child: const _SearchResultsSkeleton(),
                ),
              if (searchState.errorMessage.isNotEmpty)
                Center(
                    child: Text(searchState.errorMessage,
                        style: TextStyle(color: Colors.red))),
              if (!searchState.isLoading)
                Expanded(
                  child: searchState.results.isEmpty
                      ? Center(
                          child: Text(
                            'Keine Treffer gefunden',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.vertical,
                          itemCount: searchState.results.length,
                          itemBuilder: (context, index) {
                            final result = searchState.results[index];
                            if (result['type'] == 'show') {
                              return MainSearchShowCard(
                                id: result['data'].id,
                                title: result['data'].displayTitle,
                                genre: result['data'].genre,
                              );
                            }
                            if (result['type'] == 'attendee') {
                              return MainSearchAttendeeCard(
                                id: result['data'].id,
                                title: result['data'].name,
                              );
                            }
                            if (result['type'] == 'creator') {
                              return MainSearchCreatorCard(
                                creator: result['data'] as Creator,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResultsSkeleton extends StatelessWidget {
  const _SearchResultsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        6,
        (_) => Container(
          color: const Color(0xFF121212),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          margin: const EdgeInsets.only(bottom: 6),
          child: const Row(
            children: [
              AppSkeletonBox(width: 52, height: 52, borderRadius: BorderRadius.all(Radius.circular(8))),
              SizedBox(width: 12),
              Expanded(child: AppSkeletonLines(lines: 2, height: 12, widths: [0.7, 0.4])),
            ],
          ),
        ),
      ),
    );
  }
}
