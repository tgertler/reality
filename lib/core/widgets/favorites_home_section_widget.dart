import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/core/widgets/loading/app_skeleton.dart';
import 'package:frontend/features/favorites_management/presentation/providers/favorites_provider.dart';
import 'package:frontend/features/user_management/presentation/providers/user_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class FavoritesHomeSectionWidget extends ConsumerStatefulWidget {
  const FavoritesHomeSectionWidget({super.key});

  @override
  _FavoritesHomeSectionWidgetState createState() =>
      _FavoritesHomeSectionWidgetState();
}

class _FavoritesHomeSectionWidgetState
    extends ConsumerState<FavoritesHomeSectionWidget> {
  String? _loadedUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavoritesIfNeeded();
    });
  }

  void _loadFavoritesIfNeeded() {
    final user = ref.read(userNotifierProvider).user;
    if (user == null || _loadedUserId == user.id) {
      return;
    }

    _loadedUserId = user.id;
    ref.read(favoritesNotifierProvider.notifier).fetchFavoriteShows(user.id);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userNotifierProvider).user;

    if (user != null && _loadedUserId != user.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadFavoritesIfNeeded();
      });
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 10.0),
      child: user == null
          ? _LoginPromptRow()
          : _FavoritesSummaryRow(userId: user.id),
    );
  }
}

// ─── Login prompt ──────────────────────────────────────────────────────────────

class _LoginPromptRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            //color: AppColors.pop,
            child: Text(
              'DEINE SHOWS',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                fontSize: 10,
                color: Colors.black,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Favoriten speichern & personalisierte Infos sehen',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: Colors.white60,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.push(AppRoutes.login),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              color: AppColors.pop,
              child: Text(
                'LOGIN',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  color: const Color(0xFF1E1E1E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Compact summary banner ────────────────────────────────────────────────────

class _FavoritesSummaryRow extends ConsumerWidget {
  final String userId;
  const _FavoritesSummaryRow({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favState = ref.watch(favoritesNotifierProvider);

    if (favState.isLoading) {
      return Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: const Row(
          children: [
            AppSkeletonBox(width: 80, height: 20, borderRadius: BorderRadius.zero),
            SizedBox(width: 10),
            Expanded(child: AppSkeletonLines(lines: 1, height: 10, widths: [0.5])),
            SizedBox(width: 8),
            AppSkeletonBox(width: 70, height: 12),
          ],
        ),
      );
    }

    final count = favState.favoriteShows.length;

    return GestureDetector(
      onTap: () => context.go(AppRoutes.favorites),
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              //color: AppColors.pop,
              child: Text(
                'DEINE SHOWS',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  color: const Color.fromARGB(255, 255, 255, 255),
                  letterSpacing: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: count > 0
                  ? Text(
                      '$count ${count == 1 ? 'Show' : 'Shows'} in deinen Favoriten',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    )
                  : Text(
                      'Noch keine Favoriten',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
            ),
            const SizedBox(width: 8),
            Text(
              'Alle anzeigen',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                fontSize: 10,
                color: AppColors.pop,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.chevron_right, size: 14, color: AppColors.pop),
          ],
        ),
      ),
    );
  }
}
