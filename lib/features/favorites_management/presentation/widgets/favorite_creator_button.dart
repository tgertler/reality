import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:frontend/core/widgets/loading/app_skeleton.dart';
import 'package:frontend/features/favorites_management/presentation/providers/favorites_provider.dart';
import 'package:frontend/features/user_management/presentation/providers/user_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriteCreatorButton extends ConsumerStatefulWidget {
  final String creatorId;
  final String creatorName;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const FavoriteCreatorButton({
    super.key,
    required this.creatorId,
    required this.creatorName,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  _FavoriteCreatorButtonState createState() => _FavoriteCreatorButtonState();
}

class _FavoriteCreatorButtonState extends ConsumerState<FavoriteCreatorButton>
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

  Future<void> _checkFavorite() async {
    final riverpodUser = ref.read(userNotifierProvider).user;
    final userId =
        riverpodUser?.id ?? Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final isFavoriteUseCase = ref.read(isFavoriteCreatorProvider);
    final result = await isFavoriteUseCase(userId, widget.creatorId);
    if (mounted) setState(() => _isFavorite = result);
  }

  Future<void> _toggle() async {
    final user = ref.read(userNotifierProvider).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Melde dich an um Creators zu favorisieren'),
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
    if (_isFavorite) {
      await notifier.removeCreatorFromFavorites(user.id, widget.creatorId);
    } else {
      await notifier.addCreatorToFavorites(
          user.id, widget.creatorId, widget.creatorName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('"${widget.creatorName}" zu Favoriten hinzugefügt'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    if (mounted) {
      setState(() {
        _isFavorite = !_isFavorite;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
