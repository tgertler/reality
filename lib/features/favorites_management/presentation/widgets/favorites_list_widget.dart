import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/favorites_management/presentation/providers/favorites_provider.dart';
import 'favorite_shows_list_widget.dart';
import 'favorite_attendees_list_widget.dart';

class FavoritesListWidget extends ConsumerStatefulWidget {
  final String userId;

  const FavoritesListWidget({super.key, required this.userId});

  @override
  _FavoritesListWidgetState createState() => _FavoritesListWidgetState();
}

class _FavoritesListWidgetState extends ConsumerState<FavoritesListWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFavorites();
    });
  }

  void _fetchFavorites() {
    final favoritesNotifier = ref.read(favoritesNotifierProvider.notifier);
    favoritesNotifier.fetchFavoriteShows(widget.userId);
    favoritesNotifier.fetchFavoriteAttendees(widget.userId);
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 15.0),
          child: PreferredSize(
            preferredSize: const Size.fromHeight(50.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _tabController.animateTo(0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut),
                  child: Text(
                    'Shows',
                    style: TextStyle(
                      fontWeight: _selectedIndex == 0
                          ? FontWeight.w900
                          : FontWeight.w900,
                      color: _selectedIndex == 0
                          ? Colors.white
                          : const Color.fromARGB(88, 255, 255, 255),
                      fontSize: 23,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    // Zeige Snackbar, wenn "Teilnehmer" angeklickt wird
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Diese Funktion ist noch nicht entwickelt und kommt bald!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Text(
                    'Teilnehmer',
                    style: TextStyle(
                      fontWeight: _selectedIndex == 1
                          ? FontWeight.w900
                          : FontWeight.w900,
                      color: _selectedIndex == 1
                          ? Colors.white
                          : const Color.fromARGB(88, 255, 255, 255),
                      fontSize: 23,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              FavoriteShowsList(userId: widget.userId),
              FavoriteAttendeesList(userId: widget.userId),
            ],
          ),
        ),
      ],
    );
  }
}
