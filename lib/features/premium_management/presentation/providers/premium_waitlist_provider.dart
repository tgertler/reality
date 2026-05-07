import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/logger.dart';
import '../../data/repositories/premium_repository_impl.dart';
import '../../data/sources/premium_waitlist_data_source.dart';
import '../../domain/repositories/premium_repository.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final premiumRepositoryProvider = Provider<PremiumRepository>((ref) {
  final client = Supabase.instance.client;
  return PremiumRepositoryImpl(PremiumWaitlistDataSource(client));
});

final premiumWaitlistNotifierProvider =
    StateNotifierProvider<PremiumWaitlistNotifier, PremiumWaitlistState>((ref) {
  return PremiumWaitlistNotifier(ref.read(premiumRepositoryProvider));
});

// ── State ─────────────────────────────────────────────────────────────────────

class PremiumWaitlistState {
  final bool isOnWaitlist;
  final bool isLoading;
  final bool hasChecked;
  final String? error;

  const PremiumWaitlistState({
    this.isOnWaitlist = false,
    this.isLoading = false,
    this.hasChecked = false,
    this.error,
  });

  PremiumWaitlistState copyWith({
    bool? isOnWaitlist,
    bool? isLoading,
    bool? hasChecked,
    String? error,
  }) =>
      PremiumWaitlistState(
        isOnWaitlist: isOnWaitlist ?? this.isOnWaitlist,
        isLoading: isLoading ?? this.isLoading,
        hasChecked: hasChecked ?? this.hasChecked,
        error: error,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class PremiumWaitlistNotifier extends StateNotifier<PremiumWaitlistState> {
  final PremiumRepository _repository;
  final Logger _logger = getLogger('PremiumWaitlistNotifier');

  PremiumWaitlistNotifier(this._repository)
      : super(const PremiumWaitlistState());

  Future<void> checkStatus(String userId) async {
    if (state.hasChecked) return;
    state = state.copyWith(isLoading: true);
    try {
      final onList = await _repository.isOnWaitlist(userId);
      state = state.copyWith(
        isOnWaitlist: onList,
        isLoading: false,
        hasChecked: true,
      );
    } catch (e, st) {
      _logger.e('checkStatus failed', e, st);
      state = state.copyWith(isLoading: false, hasChecked: true, error: e.toString());
    }
  }

  Future<void> joinWaitlist(String userId) async {
    if (state.isOnWaitlist || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      await _repository.joinWaitlist(userId);
      state = state.copyWith(isOnWaitlist: true, isLoading: false);
      _logger.i('User $userId joined premium waitlist');
    } catch (e, st) {
      _logger.e('joinWaitlist failed', e, st);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
