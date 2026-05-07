import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:frontend/core/utils/logger.dart';
import 'package:frontend/core/utils/supabase_provider.dart';

const _table = 'user_preferences';
const _streamingFilterKey = 'streaming_services';

/// Canonical list of all streaming services the app tracks.
const kAllStreamingServices = [
  'Netflix',
  'RTL+',
  'Amazon Prime Video',
  'Joyn',
  'Paramount+',
];

/// Holds the set of services the user has selected (e.g. {'Netflix', 'RTL+'}).
/// An empty set means "no filter – show everything".
class StreamingFilterNotifier extends StateNotifier<Set<String>> {
  final SupabaseClient _supabaseClient;
  final _logger = getLogger('StreamingFilterNotifier');
  String? _loadedForUserId;

  StreamingFilterNotifier(this._supabaseClient) : super(const {}) {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId != null) {
      loadForUser(userId);
    }
  }

  Future<void> loadForUser(String userId) async {
    if (_loadedForUserId == userId) return;
    _logger.i('Loading streaming preferences for user: $userId');

    try {
      final response = await _supabaseClient
          .from(_table)
        .select('preference_value')
        .eq('user_id', userId)
        .eq('preference_key', _streamingFilterKey)
        .maybeSingle();

      final value = response?['preference_value'];
      final rawList = value is List ? value : const <dynamic>[];
      final services = rawList
        .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toSet();
      state = services;
      _loadedForUserId = userId;
    } catch (e, stackTrace) {
      _logger.e('Failed to load streaming preferences', e, stackTrace);
      rethrow;
    }
  }

  Future<void> toggle(String service) async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) return;

    await loadForUser(userId);

    final previous = Set<String>.from(state);
    final next = Set<String>.from(state);

    if (next.contains(service)) {
      next.remove(service);
    } else {
      next.add(service);
    }

    // Optimistic update for responsive UI.
    state = next;

    try {
      await _supabaseClient.from(_table).upsert(
        {
          'user_id': userId,
          'preference_key': _streamingFilterKey,
          'preference_value': next.toList(),
        },
        onConflict: 'user_id,preference_key',
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to update streaming preference', e, stackTrace);
      state = previous;
      rethrow;
    }
  }

  Future<void> clear() async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      state = const {};
      return;
    }

    await loadForUser(userId);
    final previous = Set<String>.from(state);
    state = const {};

    try {
      await _supabaseClient
          .from(_table)
          .delete()
          .eq('user_id', userId)
          .eq('preference_key', _streamingFilterKey);
    } catch (e, stackTrace) {
      _logger.e('Failed to clear streaming preferences', e, stackTrace);
      state = previous;
      rethrow;
    }
  }
}

final streamingServiceFilterProvider =
    StateNotifierProvider<StreamingFilterNotifier, Set<String>>(
  (ref) => StreamingFilterNotifier(ref.read(supabaseClientProvider)),
);

/// Returns true when [option] passes the active streaming filter.
///
/// Rules:
/// - Empty [filter] → always passes (no filter set).
/// - Null/blank [option] → always passes (platform unknown, don't hide it).
/// - Otherwise the option must match one of the selected services
///   (case-insensitive).
bool passesStreamingFilter(String? option, Set<String> filter) {
  if (filter.isEmpty) return true;
  if (option == null || option.trim().isEmpty) return true;
  return filter.any((f) => f.toLowerCase() == option.trim().toLowerCase());
}
