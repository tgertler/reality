import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/core/widgets/loading/app_skeleton.dart';
import 'package:frontend/features/favorites_management/presentation/providers/favorites_provider.dart';
import 'package:frontend/features/user_management/presentation/providers/user_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriteHeartButton extends ConsumerStatefulWidget {
  final String showId;
  final String showTitle;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const FavoriteHeartButton({
    super.key,
    required this.showId,
    required this.showTitle,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  _FavoriteHeartButtonState createState() => _FavoriteHeartButtonState();
}

class _FavoriteHeartButtonState extends ConsumerState<FavoriteHeartButton>
    with SingleTickerProviderStateMixin {
  bool _isFavorite = false;
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.45, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFavorite());
  }

  String? _resolveUserId() {
    final riverpodUser = ref.read(userNotifierProvider).user;
    if (riverpodUser != null) {
      return riverpodUser.id;
    }

    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _checkFavorite() async {
    final userId = _resolveUserId();
    if (userId == null) return;
    final isFavoriteUseCase = ref.read(isFavoriteShowProvider);
    final result = await isFavoriteUseCase(userId, widget.showId);
    if (mounted) setState(() => _isFavorite = result);
  }

  @override
  void didUpdateWidget(covariant FavoriteHeartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showId != widget.showId) {
      _checkFavorite();
    }
  }

  Future<void> _toggle() async {
    final userId = _resolveUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: false,
          content: const Text('Melde dich an um Shows zu favorisieren'),
          action: SnackBarAction(
            label: 'Login',
            onPressed: () => context.push(AppRoutes.login),
          ),
        ),
      );
      return;
    }
    if (_isLoading) return;
    setState(() => _isLoading = true);
    _controller.forward(from: 0);

    final notifier = ref.read(favoritesNotifierProvider.notifier);
    try {
      if (_isFavorite) {
        await notifier.removeShowFromFavorites(userId, widget.showId);
      } else {
        await notifier.addShowToFavorites(userId, widget.showId, widget.showTitle);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${widget.showTitle}" zu Favoriten hinzugefügt'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }

      ref.refresh(favoriteShowCountProvider(widget.showId));

      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Favorit konnte nicht gespeichert werden'),
            duration: Duration(seconds: 2),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FavoritesState>(favoritesNotifierProvider, (previous, next) {
      final providerValue =
          next.favoriteShows.any((show) => show.showId == widget.showId);
      if (mounted && !_isLoading && providerValue != _isFavorite) {
        setState(() => _isFavorite = providerValue);
      }
    });

    // Re-check when user loads (handles race between async user init and initState)
    ref.listen<UserState>(userNotifierProvider, (previous, next) {
      if (previous?.user == null && next.user != null) {
        _checkFavorite();
      }
    });

    final activeColor = widget.activeColor ?? AppColors.pop;
    final inactiveColor = widget.inactiveColor ?? Colors.white54;

    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: _isLoading
              ? SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: AppSkeletonCircle(size: widget.size),
                )
              : Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? activeColor : inactiveColor,
                  size: widget.size,
                ),
        ),
      ),
    );
  }
}
