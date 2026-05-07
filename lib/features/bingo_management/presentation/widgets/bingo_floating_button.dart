import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/config/app_colors.dart';
import 'package:frontend/features/bingo_management/presentation/providers/bingo_session_provider.dart';

class BingoFloatingButton extends ConsumerWidget {
  final double bottomOffset;

  const BingoFloatingButton({
    super.key,
    this.bottomOffset = 96,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bingoSessionProvider);
    final active = state.activeSession;

    if (active == null) return const SizedBox.shrink();

    return Positioned(
      right: 14,
      bottom: bottomOffset,
      child: SafeArea(
        child: Tooltip(
          message: 'Aktive Bingo-Session öffnen',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () =>
                  ref.read(bingoSessionProvider.notifier).openActiveSessionOverlay(),
              child: Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.secondary.withValues(alpha: 0.95),
                      AppColors.secondary.withValues(alpha: 0.45),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF101010),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Icon(
                    Icons.live_tv_rounded,
                    color: active.bingoReached ? AppColors.secondary : Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}
