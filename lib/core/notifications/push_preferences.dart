enum PushNotificationType {
  dailyDigest,
  dailyDigestFavorite,
  calendarEventReminder,
}

extension PushNotificationTypeX on PushNotificationType {
  String get storageValue {
    switch (this) {
      case PushNotificationType.dailyDigest:
        return 'DAILY_DIGEST';
      case PushNotificationType.dailyDigestFavorite:
        return 'DAILY_DIGEST_FAVORITE';
      case PushNotificationType.calendarEventReminder:
        return 'CALENDAR_EVENT_REMINDER';
    }
  }

  String get label {
    switch (this) {
      case PushNotificationType.dailyDigest:
        return 'Tagesübersicht';
      case PushNotificationType.dailyDigestFavorite:
        return 'Tagesübersicht (Favoriten)';
      case PushNotificationType.calendarEventReminder:
        return 'Event-Erinnerungen';
    }
  }

  String get subtitle {
    switch (this) {
      case PushNotificationType.dailyDigest:
        return 'Ein täglicher Überblick über alle wichtigen Events';
      case PushNotificationType.dailyDigestFavorite:
        return 'Dein Tagesüberblick nur für favorisierte Shows';
      case PushNotificationType.calendarEventReminder:
        return 'Erinnerungen vor konkreten Kalender-Events';
    }
  }

  static PushNotificationType? fromStorageValue(String value) {
    final normalized = value.trim().toUpperCase();

    switch (normalized) {
      case 'DAILY_DIGEST':
      case 'DAILY_OVERVIEW':
      case 'LIVE':
        return PushNotificationType.dailyDigest;
      case 'DAILY_DIGEST_FAVORITE':
      case 'DAILY_DIGEST_FAVORITES':
      case 'DAILY_OVERVIEW_FAVORITES':
        return PushNotificationType.dailyDigestFavorite;
      case 'CALENDAR_EVENT_REMINDER':
      case 'ONE_HOUR_BEFORE':
      case 'ONE_DAY_BEFORE':
      case 'TWO_DAYS_BEFORE':
        return PushNotificationType.calendarEventReminder;
      default:
        return null;
    }
  }
}

class PushNotificationPreferences {
  final bool enabled;
  final Set<PushNotificationType> notificationTypes;

  const PushNotificationPreferences({
    required this.enabled,
    required this.notificationTypes,
  });

  const PushNotificationPreferences.defaults()
      : enabled = true,
        notificationTypes = const {
          PushNotificationType.dailyDigest,
          PushNotificationType.dailyDigestFavorite,
          PushNotificationType.calendarEventReminder,
        };

  factory PushNotificationPreferences.fromPreferenceValue(dynamic value) {
    if (value is Map) {
      final enabled =
          value['enabled'] is bool ? value['enabled'] as bool : true;
      final rawTypes = value['notification_types'] ?? value['reminder_types'];
      final parsedTypes = <PushNotificationType>{};
      final hasExplicitTypeList = rawTypes is List;

      if (rawTypes is List) {
        for (final item in rawTypes) {
          final type = PushNotificationTypeX.fromStorageValue(item.toString());
          if (type != null) {
            parsedTypes.add(type);
          }
        }
      }

      return PushNotificationPreferences(
        enabled: enabled,
        notificationTypes: hasExplicitTypeList
            ? parsedTypes
            : const PushNotificationPreferences.defaults().notificationTypes,
      );
    }

    return const PushNotificationPreferences.defaults();
  }

  PushNotificationPreferences copyWith({
    bool? enabled,
    Set<PushNotificationType>? notificationTypes,
  }) {
    return PushNotificationPreferences(
      enabled: enabled ?? this.enabled,
      notificationTypes: notificationTypes ?? this.notificationTypes,
    );
  }

  bool isNotificationTypeEnabled(PushNotificationType type) {
    return notificationTypes.contains(type);
  }

  Map<String, dynamic> toPreferenceValue() {
    return {
      'enabled': enabled,
      'notification_types':
          notificationTypes.map((type) => type.storageValue).toList(),
    };
  }
}
