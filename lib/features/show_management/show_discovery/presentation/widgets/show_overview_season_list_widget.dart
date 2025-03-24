import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/show_management/show_discovery/presentation/providers/seasons_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'season_list_item_widget.dart';

class SeasonListWidget extends ConsumerStatefulWidget {
  final String showId;

  const SeasonListWidget({super.key, required this.showId});

  @override
  _SeasonListWidgetState createState() => _SeasonListWidgetState();
}

class _SeasonListWidgetState extends ConsumerState<SeasonListWidget> {
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

  @override
  Widget build(BuildContext context) {
    final seasonState = ref.watch(seasonsNotifierProvider);

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
                ),
              ),
            ),
          ),
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
          ),
        ],
      ),
    );
  }
}
