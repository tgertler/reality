import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/notifications/push_notification_service.dart';
import 'package:frontend/core/notifications/push_preferences.dart';
import 'package:frontend/core/utils/logger.dart';
import 'package:frontend/core/utils/supabase_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _table = 'user_preferences';
const _pushSettingsKey = 'push_notification_settings';

class PushNotificationPreferencesNotifier
    extends StateNotifier<PushNotificationPreferences> {
  PushNotificationPreferencesNotifier(this._supabaseClient)
      : super(const PushNotificationPreferences.defaults()) {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId != null) {
      loadForUser(userId);
    }
  }

  final SupabaseClient _supabaseClient;
  final _logger = getLogger('PushNotificationPreferencesNotifier');
  String? _loadedForUserId;

  Future<void> loadForUser(String userId) async {
    if (_loadedForUserId == userId) {
      return;
    }

    try {
      final response = await _supabaseClient
          .from(_table)
          .select('preference_value')
          .eq('user_id', userId)
          .eq('preference_key', _pushSettingsKey)
          .maybeSingle();

      state = PushNotificationPreferences.fromPreferenceValue(
        response?['preference_value'],
      );
      _loadedForUserId = userId;
    } catch (e, stackTrace) {
      _logger.e('Failed to load push notification preferences', e, stackTrace);
      rethrow;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      return;
    }

    await loadForUser(userId);

    final previous = state;
    final next = state.copyWith(enabled: enabled);
    state = next;

    try {
      await _persist(userId, next);
      await PushNotificationService.instance.applyUserNotificationPreference(
        enabled,
      );
    } catch (e, stackTrace) {
      _logger.e('Failed to update push enabled preference', e, stackTrace);
      state = previous;
      rethrow;
    }
  }

  Future<void> toggleNotificationType(PushNotificationType type) async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      return;
    }

    await loadForUser(userId);

    final previous = state;
    final nextTypes = Set<PushNotificationType>.from(state.notificationTypes);
    if (nextTypes.contains(type)) {
      nextTypes.remove(type);
    } else {
      nextTypes.add(type);
    }

    final next = state.copyWith(notificationTypes: nextTypes);
    state = next;

    try {
      await _persist(userId, next);
    } catch (e, stackTrace) {
      _logger.e('Failed to update push notification types', e, stackTrace);
      state = previous;
      rethrow;
    }
  }

  Future<void> _persist(
    String userId,
    PushNotificationPreferences preferences,
  ) async {
    await _supabaseClient.from(_table).upsert(
      {
        'user_id': userId,
        'preference_key': _pushSettingsKey,
        'preference_value': preferences.toPreferenceValue(),
      },
      onConflict: 'user_id,preference_key',
    );
  }
}

final pushNotificationPreferencesProvider = StateNotifierProvider<
    PushNotificationPreferencesNotifier, PushNotificationPreferences>(
  (ref) =>
      PushNotificationPreferencesNotifier(ref.read(supabaseClientProvider)),
);
