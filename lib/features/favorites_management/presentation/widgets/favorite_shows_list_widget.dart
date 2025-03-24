import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/favorites_provider.dart';

class FavoriteShowsList extends ConsumerStatefulWidget {
  final String userId;

  const FavoriteShowsList({Key? key, required this.userId}) : super(key: key);

  @override
  _FavoriteShowsListState createState() => _FavoriteShowsListState();
}

class _FavoriteShowsListState extends ConsumerState<FavoriteShowsList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFavoriteShows();
    });
  }

  void _fetchFavoriteShows() {
    final favoritesNotifier = ref.read(favoritesNotifierProvider.notifier);
    favoritesNotifier.fetchFavoriteShows(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final favoritesState = ref.watch(favoritesNotifierProvider);

    if (favoritesState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (favoritesState.errorMessage.isNotEmpty) {
      return Text('Error: ${favoritesState.errorMessage}');
    }

    final shows = favoritesState.favoriteShows;

    if (shows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Du hast derzeit noch keine Favoriten.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 15),
            Text(
              'Um eine Show zu favorisieren, klicke auf das Herz-Symbol bei deiner Lieblingsshow. ',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: ListView.builder(
        itemCount: shows.length,
        itemBuilder: (context, index) {
          final show = shows[index];
          return Container(
            color: index.isEven
                ? const Color.fromARGB(255, 30, 30, 30)
                : const Color.fromARGB(255, 56, 56, 56),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  height: 50,
                  width: 5,
                  color: Colors.white,
                ),
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.only(left: 15.0),
                  child: Text(show.title, style: TextStyle(fontSize: 16.0)),
                )),
                IconButton(
                  icon: Icon(Icons.favorite, color: Colors.red),
                  onPressed: () async {
                    await ref
                        .read(favoritesNotifierProvider.notifier)
                        .removeShowFromFavorites(widget.userId, show.showId);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
