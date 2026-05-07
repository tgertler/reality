import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:frontend/core/utils/logger.dart';
import 'package:frontend/core/utils/supabase_provider.dart';

const _table = 'user_preferences';
const _cityFilterKey = 'trash_event_city';

/// The five largest cities in Germany supported by the city filter.
const kTopGermanCities = [
  'Berlin',
  'Hamburg',
  'München',
  'Köln',
  'Frankfurt am Main',
];

/// Holds exactly one selected city or null for "all cities".
class TrashEventCityFilterNotifier extends StateNotifier<String?> {
  final SupabaseClient _supabaseClient;
  final _logger = getLogger('TrashEventCityFilterNotifier');
  String? _loadedForUserId;

  TrashEventCityFilterNotifier(this._supabaseClient) : super(null) {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId != null) {
      loadForUser(userId);
    }
  }

  Future<void> loadForUser(String userId) async {
    if (_loadedForUserId == userId) return;

    try {
      final response = await _supabaseClient
          .from(_table)
          .select('preference_value')
          .eq('user_id', userId)
          .eq('preference_key', _cityFilterKey)
          .maybeSingle();

      final value = response?['preference_value'];
      final selected = value?.toString().trim();

      if (selected == null || selected.isEmpty || !_isAllowedCity(selected)) {
        state = null;
      } else {
        state = selected;
      }

      _loadedForUserId = userId;
    } catch (e, stackTrace) {
      _logger.e('Failed to load trash city preference', e, stackTrace);
      rethrow;
    }
  }

  Future<void> setCity(String? city) async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      state = null;
      return;
    }

    await loadForUser(userId);

    final normalizedCity = city?.trim();
    final next = (normalizedCity == null || normalizedCity.isEmpty)
        ? null
        : (_isAllowedCity(normalizedCity) ? normalizedCity : null);

    final previous = state;
    state = next;

    try {
      if (next == null) {
        await _supabaseClient
            .from(_table)
            .delete()
            .eq('user_id', userId)
            .eq('preference_key', _cityFilterKey);
      } else {
        await _supabaseClient.from(_table).upsert(
          {
            'user_id': userId,
            'preference_key': _cityFilterKey,
            'preference_value': next,
          },
          onConflict: 'user_id,preference_key',
        );
      }
    } catch (e, stackTrace) {
      _logger.e('Failed to update trash city preference', e, stackTrace);
      state = previous;
      rethrow;
    }
  }

  bool _isAllowedCity(String city) {
    return kTopGermanCities.any(
      (allowed) => _normalize(allowed) == _normalize(city),
    );
  }
}

final trashEventCityFilterProvider =
    StateNotifierProvider<TrashEventCityFilterNotifier, String?>(
  (ref) => TrashEventCityFilterNotifier(ref.read(supabaseClientProvider)),
);

/// Returns true when [location] matches [selectedCity] or no city is selected.
bool passesTrashCityFilter(String? location, String? selectedCity) {
  if (selectedCity == null || selectedCity.trim().isEmpty) {
    return true;
  }

  if (location == null || location.trim().isEmpty) {
    return false;
  }

  final selected = _normalize(selectedCity);
  final normalizedLocation = _normalize(location);

  if (normalizedLocation.contains(selected)) {
    return true;
  }

  // Also match Frankfurt events written without "am Main".
  if (selected == 'frankfurt am main' && normalizedLocation.contains('frankfurt')) {
    return true;
  }

  return false;
}

String _normalize(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss');
}
