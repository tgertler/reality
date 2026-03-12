import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/widgets/todays_shows_widget.dart';
import 'package:frontend/features/calendar_management/domain/entities/calendar_event.dart';
import 'package:frontend/features/calendar_management/presentation/providers/calendar_events_provider.dart';
import 'package:frontend/core/widgets/new_releases_widget.dart';

class HomeStreamingContentWidget extends ConsumerStatefulWidget {
  const HomeStreamingContentWidget({super.key});

  @override
  _HomeStreamingContentWidgetState createState() =>
      _HomeStreamingContentWidgetState();
}

class _HomeStreamingContentWidgetState
    extends ConsumerState<HomeStreamingContentWidget> {
  // ZWEI separate PageController!
  final PageController _lastReleasesPageController = PageController(
    viewportFraction: 0.48,
  );

  final PageController _nextReleasesPageController = PageController(
    viewportFraction: 0.48,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeEventsNotifierProvider.notifier).loadHomeData();
    });
  }

  @override
  void dispose() {
    _lastReleasesPageController.dispose();
    _nextReleasesPageController.dispose(); // Beide disposen!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showsReleasingTodayState = ref.watch(homeEventsNotifierProvider);
    final nextThreePremieresState = showsReleasingTodayState.nextPremieres;
    final lastThreeReleasesState = showsReleasingTodayState.lastPremieres;

    // Debug-Ausgabe
    print('=== DEBUG HOME STREAMING ===');
    print('Last releases count: ${lastThreeReleasesState.length}');
    print('Next releases count: ${nextThreePremieresState.length}');
    for (var event in lastThreeReleasesState) {
      print(
          'LAST: ${event.show.title} - Streaming: ${event.season.streamingOption}');
    }
    for (var event in nextThreePremieresState) {
      print(
          'NEXT: ${event.show.title} - Streaming: ${event.season.streamingOption}');
    }
    print('==========================');

    return Container(
      padding: const EdgeInsets.only(
        left: 20.0,
        right: 20.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(
              top: 10.0,
              bottom: 10.0,
            ),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color.fromARGB(255, 29, 29, 29),
            ),
            constraints: const BoxConstraints(
              maxHeight: 250,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 15.0, left: 15.0, right: 15.0, bottom: 15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Heute',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    showsReleasingTodayState.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : showsReleasingTodayState.errorMessage.isNotEmpty
                            ? Center(
                                child: Text(
                                    'Error: ${showsReleasingTodayState.errorMessage}'))
                            : showsReleasingTodayState.events.isEmpty
                                ? const Text(
                                    'Heute gibt es nichts zu schauen!',
                                    style: TextStyle(color: Colors.grey),
                                  )
                                : TodayShowsWidget(
                                    events: showsReleasingTodayState.events),
                  ],
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(
              top: 10.0,
              bottom: 10.0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: const Color.fromARGB(255, 29, 29, 29),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 15.0, left: 15.0, right: 15.0, bottom: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Neuerscheinungen',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Zuletzt',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: Container(
                            height: 1.5,
                            width: double.infinity,
                            color: const Color.fromARGB(255, 41, 41, 41),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  lastThreeReleasesState.isEmpty
                      ? const Text(
                          'Keine zuletzt erschienenen Shows',
                          style: TextStyle(color: Colors.grey),
                        )
                      : SizedBox(
                          height: 135,
                          child: NewReleasesWidget(
                            events: lastThreeReleasesState,
                            pageController:
                                _lastReleasesPageController, // Eigener Controller
                          ),
                        ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        'Demnächst',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: Container(
                            height: 1.5,
                            width: double.infinity,
                            color: const Color.fromARGB(255, 41, 41, 41),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  nextThreePremieresState.isEmpty
                      ? const Text(
                          'Keine demnächst erscheinenden Shows',
                          style: TextStyle(color: Colors.grey),
                        )
                      : SizedBox(
                          height: 135,
                          child: NewReleasesWidget(
                            events: nextThreePremieresState,
                            pageController:
                                _nextReleasesPageController, // Eigener Controller
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
