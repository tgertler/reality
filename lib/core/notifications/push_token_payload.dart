import 'package:flutter/foundation.dart';

enum PushPlatform {
  ios,
  android,
  web,
}

class PushPlatformMapper {
  const PushPlatformMapper._();

  static PushPlatform? fromTargetPlatform(
    TargetPlatform platform, {
    bool isWeb = kIsWeb,
  }) {
    if (isWeb) {
      return PushPlatform.web;
    }

    switch (platform) {
      case TargetPlatform.iOS:
        return PushPlatform.ios;
      case TargetPlatform.android:
        return PushPlatform.android;
      default:
        return null;
    }
  }
}

Map<String, dynamic> buildDeviceTokenPayload({
  required String deviceRecordId,
  required String userId,
  required PushPlatform platform,
  required String fcmToken,
  bool isActive = true,
  DateTime? lastSeenAt,
}) {
  final timestamp = (lastSeenAt ?? DateTime.now().toUtc()).toIso8601String();

  return {
    'id': deviceRecordId,
    'user_id': userId,
    'fcm_token': fcmToken,
    'platform': platform.name,
    'is_active': isActive,
    'last_seen_at': timestamp,
  };
}
