import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/providers/trash_event_city_filter_provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/category_filter_provider.dart';
import '../providers/filter_active_provider.dart';

class FilterOverlayContentWidget extends ConsumerWidget {
  const FilterOverlayContentWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFiltersState = ref.watch(activeFiltersProvider);
    final selectedGenres = ref.watch(selectedGenreFiltersProvider);
    final genresAsync = ref.watch(availableCalendarGenresProvider);
    final selectedTrashCity = ref.watch(trashEventCityFilterProvider);
    final trashCityFilterNotifier = ref.read(trashEventCityFilterProvider.notifier);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.black),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Container(
                    child: Text(
                      "Shows",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: GoogleFonts.montserrat().fontFamily,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 23.0, top: 8.0),
                child: activeFiltersState.activeShows.isEmpty
                    ? Container(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "Kein Filter ausgewählt",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 168, 168, 168),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: activeFiltersState.activeShows.length,
                        itemBuilder: (context, index) {
                          final show = activeFiltersState.activeShows[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 7, 103, 103),
                              borderRadius: BorderRadius.circular(50.0),
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 20.0, right: 20.0),
                                        child: Text(
                                          show.displayTitle.isEmpty
                                              ? 'No Title'
                                              : show.displayTitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      if ((show.genre?.trim().isNotEmpty ?? false))
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 20.0, right: 20.0, top: 3),
                                          child: Text(
                                            show.genre!.trim(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.white),
                                  onPressed: () {
                                    ref
                                        .read(activeFiltersProvider.notifier)
                                        .removeShow(show.showId);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Text(
                    'Genres',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: GoogleFonts.montserrat().fontFamily,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            genresAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 6.0, bottom: 8.0),
                child: SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (genres) {
                if (genres.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: genres.map((genre) {
                    final selected = selectedGenres.any(
                      (value) => value.toLowerCase() == genre.toLowerCase(),
                    );
                    return InkWell(
                      onTap: () {
                        ref
                            .read(selectedGenreFiltersProvider.notifier)
                            .toggle(genre);
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color.fromARGB(255, 248, 144, 255)
                              : const Color.fromARGB(255, 30, 30, 30),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: selected
                                ? const Color.fromARGB(255, 248, 144, 255)
                                : Colors.white24,
                          ),
                        ),
                        child: Text(
                          genre,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFF1E1E1E)
                                : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Text(
                    'Community-Stadt',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: GoogleFonts.montserrat().fontFamily,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                InkWell(
                  onTap: () => trashCityFilterNotifier.setCity(null),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selectedTrashCity == null
                          ? const Color(0xFFFFD700)
                          : const Color.fromARGB(255, 30, 30, 30),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selectedTrashCity == null
                            ? const Color(0xFFFFD700)
                            : Colors.white24,
                      ),
                    ),
                    child: Text(
                      'Alle',
                      style: TextStyle(
                        color: selectedTrashCity == null
                            ? const Color(0xFF1E1E1E)
                            : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                ...kTopGermanCities.map((city) {
                  final selected = selectedTrashCity?.toLowerCase() == city.toLowerCase();
                  return InkWell(
                    onTap: () => trashCityFilterNotifier.setCity(city),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFFFD700)
                            : const Color.fromARGB(255, 30, 30, 30),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFFFFD700)
                              : Colors.white24,
                        ),
                      ),
                      child: Text(
                        city,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF1E1E1E)
                              : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
/*             Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Container(
                    child: Text(
                      "Teilnehmer",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: GoogleFonts.montserrat().fontFamily,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.white,
                  ),
                ),
              ],
            ), */
            /* Flexible(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 23.0, top: 8.0),
                child: activeFiltersState.activeAttendees.isEmpty
                    ? Container(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "Kein Filter ausgewählt",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 168, 168, 168),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: activeFiltersState.activeAttendees.length,
                        itemBuilder: (context, index) {
                          final attendee = activeFiltersState.activeAttendees[index];
                          return Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 7, 103, 103),
                              borderRadius: BorderRadius.circular(50.0),
                            ),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(left: 20.0),
                                      child: Text(
                                        attendee.name ?? 'No Name',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.white),
                                  onPressed: () {
                                    ref
                                        .read(activeFiltersProvider.notifier)
                                        .removeAttendee(attendee.id);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ), */
          ],
        ),
      ),
    );
  }
}
