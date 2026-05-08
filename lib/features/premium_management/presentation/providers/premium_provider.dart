import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/logger.dart';
import '../../domain/services/premium_billing_service.dart';
import '../../../user_management/presentation/providers/user_provider.dart';

class PremiumState {
  final bool isPremium;
  final bool isLoading;
  final bool hasChecked;
  final String? error;

  const PremiumState({
    this.isPremium = false,
    this.isLoading = false,
    this.hasChecked = false,
    this.error,
  });

  PremiumState copyWith({
    bool? isPremium,
    bool? isLoading,
    bool? hasChecked,
    String? error,
    bool clearError = false,
  }) {
    return PremiumState(
      isPremium: isPremium ?? this.isPremium,
      isLoading: isLoading ?? this.isLoading,
      hasChecked: hasChecked ?? this.hasChecked,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final premiumServiceProvider = Provider<PremiumBillingService>((ref) {
  return PremiumBillingService(Supabase.instance.client);
});

final premiumNotifierProvider =
    StateNotifierProvider<PremiumNotifier, PremiumState>((ref) {
  return PremiumNotifier(ref, ref.read(premiumServiceProvider));
});

final isPremiumProvider = Provider<bool>((ref) {
  final premiumState = ref.watch(premiumNotifierProvider);
  if (premiumState.isPremium) return true;
  return ref.watch(userNotifierProvider).profile?.isPremium ?? false;
});

class PremiumNotifier extends StateNotifier<PremiumState> {
  final Ref _ref;
  final PremiumBillingService _premiumService;
  final Logger _logger = getLogger('PremiumNotifier');

  PremiumNotifier(this._ref, this._premiumService)
      : super(const PremiumState()) {
    final initialProfile = _ref.read(userNotifierProvider).profile;
    state = state.copyWith(isPremium: initialProfile?.isPremium ?? false);

    _ref.listen<UserState>(userNotifierProvider, (previous, next) {
      state = state.copyWith(isPremium: next.profile?.isPremium ?? false);
    });
  }

  Future<void> refreshStatus({bool force = false}) async {
    final user = _ref.read(userNotifierProvider).user;
    if (user == null) return;
    if (state.hasChecked && !force) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final isPremium = await _premiumService.refreshPremiumStatus(user.id);
      await _ref.read(userNotifierProvider.notifier).loadUserData();
      state = state.copyWith(
        isLoading: false,
        hasChecked: true,
        isPremium: isPremium,
      );
    } catch (e, st) {
      _logger.e('refreshStatus failed', e, st);
      state = state.copyWith(
        isLoading: false,
        hasChecked: true,
        error: e.toString(),
      );
    }
  }

  Future<bool> purchaseMonthly() async {
    final user = _ref.read(userNotifierProvider).user;
    if (user == null) {
      state = state.copyWith(error: 'Du musst eingeloggt sein.', isLoading: false);
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _premiumService.purchaseMonthlySubscription(user.id);
      final isPremium = await _premiumService.refreshPremiumStatus(
        user.id,
        retries: 5,
      );
      await _ref.read(userNotifierProvider.notifier).loadUserData();

      if (!isPremium) {
        state = state.copyWith(
          isLoading: false,
          error:
              'Kauf wurde verarbeitet, aber Premium ist noch nicht synchron. Bitte gleich erneut pruefen.',
        );
        return false;
      }

      state = state.copyWith(
        isLoading: false,
        isPremium: true,
      );
      return true;
    } catch (e, st) {
      _logger.e('purchaseMonthly failed', e, st);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> restore() async {
    final user = _ref.read(userNotifierProvider).user;
    if (user == null) {
      state = state.copyWith(error: 'Du musst eingeloggt sein.', isLoading: false);
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _premiumService.restorePurchases(user.id);
      final isPremium = await _premiumService.refreshPremiumStatus(
        user.id,
        retries: 5,
      );
      await _ref.read(userNotifierProvider.notifier).loadUserData();

      state = state.copyWith(
        isLoading: false,
        isPremium: isPremium,
      );
      return isPremium;
    } catch (e, st) {
      _logger.e('restore failed', e, st);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
}
