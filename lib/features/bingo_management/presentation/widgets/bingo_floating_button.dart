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

    final hasBingo = active.bingoReached;

    return Positioned(
      right: 14,
      bottom: bottomOffset,
      child: SafeArea(
        child: GestureDetector(
          onTap: () =>
              ref.read(bingoSessionProvider.notifier).openActiveSessionOverlay(),
          child: Transform.rotate(
            angle: -0.02,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hasBingo ? AppColors.secondary : Colors.black,
                border: Border.all(
                  color: hasBingo ? Colors.black : AppColors.secondary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                hasBingo ? Icons.star_rounded : Icons.live_tv_rounded,
                size: 22,
                color: hasBingo ? Colors.black : AppColors.secondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

