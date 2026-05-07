import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/core/widgets/loading/app_skeleton.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/favorites_provider.dart';

class FavoriteShowsList extends ConsumerStatefulWidget {
  final String userId;

  const FavoriteShowsList({super.key, required this.userId});

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
      return const Padding(
        padding: EdgeInsets.only(top: 10.0),
        child: _FavoriteShowListSkeleton(),
      );
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
              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
            SizedBox(height: 10),
            Text(
              'Tippe das Herz-Symbol bei deiner Lieblingsshow.',
              style: TextStyle(color: Colors.white24, fontSize: 12),
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
          return GestureDetector(
            onTap: () =>
                context.push('${AppRoutes.showOverview}/${show.showId}'),
            child: Container(
              color: Colors.black,
              margin: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Container(width: 4, height: 56, color: AppColors.pop),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      show.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite,
                        color: AppColors.pop, size: 20),
                    onPressed: () async {
                      await ref
                          .read(favoritesNotifierProvider.notifier)
                          .removeShowFromFavorites(
                              widget.userId, show.showId);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FavoriteShowListSkeleton extends StatelessWidget {
  const _FavoriteShowListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => Container(
          color: Colors.black,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: const Row(
            children: [
              AppSkeletonBox(width: 4, height: 40, borderRadius: BorderRadius.zero),
              SizedBox(width: 14),
              Expanded(child: AppSkeletonBox(height: 14)),
              SizedBox(width: 10),
              AppSkeletonCircle(size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
