import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/show_management/show_discovery/presentation/providers/seasons_provider.dart';
<<<<<<< HEAD
=======
import 'package:google_fonts/google_fonts.dart';
>>>>>>> 2275eb12469187351262114ef8e8ec75d1ca9801
import 'season_list_item_widget.dart';

class SeasonListWidget extends ConsumerStatefulWidget {
  final String showId;

  const SeasonListWidget({super.key, required this.showId});

  @override
  _SeasonListWidgetState createState() => _SeasonListWidgetState();
}

class _SeasonListWidgetState extends ConsumerState<SeasonListWidget> {
<<<<<<< HEAD
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(seasonsNotifierProvider.notifier)
          .getSeasonsByShow(widget.showId);
    });
  }

  @override
  void didUpdateWidget(covariant SeasonListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showId != widget.showId) {
      setState(() => _isExpanded = false);
      ref
          .read(seasonsNotifierProvider.notifier)
          .getSeasonsByShow(widget.showId);
    }
  }
=======
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(seasonsNotifierProvider.notifier);
      print('Calling getSeasonsByShow with showId: ${widget.showId}');
      notifier.getSeasonsByShow(widget.showId).then((_) {
        print('getSeasonsByShow completed');
      }).catchError((error) {
        print('Error in getSeasonsByShow: $error');
      });
    });
  }
>>>>>>> 2275eb12469187351262114ef8e8ec75d1ca9801

  @override
  Widget build(BuildContext context) {
    final seasonState = ref.watch(seasonsNotifierProvider);

<<<<<<< HEAD
    if (seasonState.isLoading && seasonState.seasons.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (seasonState.seasons.isEmpty && !seasonState.isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header mit Toggle
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.movie_filter_outlined,
                      color: Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Staffeln',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 66, 66, 66),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${seasonState.seasons.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white70,
                        size: 24,
                      ),
                    ),
                  ],
=======
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.black,
                  width: 1,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 20.0, bottom: 5),
              child: Text(
                'Staffeln',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  fontFamily: GoogleFonts.bricolageGrotesque().fontFamily,
>>>>>>> 2275eb12469187351262114ef8e8ec75d1ca9801
                ),
              ),
            ),
          ),
<<<<<<< HEAD
          // Collapsible Content
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 12.0,
              ),
              child: Column(
                children: [
                  if (seasonState.errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              seasonState.errorMessage,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: seasonState.seasons.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 0),
                      itemBuilder: (context, index) {
                        final season = seasonState.seasons[index];
                        return SeasonListItemWidget(
                          season: season,
                        );
                      },
                    ),
                ],
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
=======
          Expanded(
            child: seasonState.isLoading
                ? Center(child: CircularProgressIndicator())
                : seasonState.errorMessage.isNotEmpty
                    ? Center(child: Text('Error: ${seasonState.errorMessage}'))
                    : ListView.builder(
                        itemCount: seasonState.seasons.length,
                        itemBuilder: (context, index) {
                          final season = seasonState.seasons[index];
                          return SeasonListItemWidget(season: season);
                        },
                      ),
>>>>>>> 2275eb12469187351262114ef8e8ec75d1ca9801
          ),
        ],
      ),
    );
  }
}
