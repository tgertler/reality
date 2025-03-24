import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/favorites_provider.dart';

class FavoriteAttendeesList extends ConsumerStatefulWidget {
  final String userId;

  const FavoriteAttendeesList({Key? key, required this.userId})
      : super(key: key);

  @override
  _FavoriteAttendeesListState createState() => _FavoriteAttendeesListState();
}

class _FavoriteAttendeesListState extends ConsumerState<FavoriteAttendeesList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFavoriteAttendees();
    });
  }

  void _fetchFavoriteAttendees() {
    final favoritesNotifier = ref.read(favoritesNotifierProvider.notifier);
    favoritesNotifier.fetchFavoriteAttendees(widget.userId);
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

    final attendees = favoritesState.favoriteAttendees;

    if (attendees.isEmpty) {
      return const Text(
        'Diese Funktion ist noch nicht verfügbar.',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Container(); /* ListView.builder(
      itemCount: attendees.length,
      itemBuilder: (context, index) {
        final attendee = attendees[index];
        return ListTile(
          title: Text(attendee.name),
          trailing: IconButton(
            icon: Icon(Icons.favorite, color: Colors.red),
            onPressed: () async {
              await ref.read(favoritesNotifierProvider.notifier).removeAttendeeFromFavorites(widget.userId, attendee.attendeeId);
            },
          ),
        );
      },
    ); */
  }
}
