import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:frontend/core/notifications/push_preferences.dart';
import 'package:frontend/core/notifications/push_token_payload.dart';
import 'package:frontend/core/utils/router.dart';
import 'package:logger/logger.dart';
import 'package:frontend/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

bool canSyncTokenForAuthorizationStatus(AuthorizationStatus status) {
  return status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;
}

String? resolvePushRouteFromData(Map<String, dynamic> data) {
  String? readValue(List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  final explicitRoute = readValue(['route', 'deep_link', 'deepLink']);
  if (explicitRoute != null) {
    return explicitRoute;
  }

  final showEventId = readValue([
    'show_event_id',
    'showEventId',
    'event_id',
  ]);
  if (showEventId != null) {
    return '${AppRoutes.showEventDetail}/$showEventId';
  }

  final showId = readValue([
    'show_id',
    'showId',
    'show_event_show_id',
    'related_show_id',
  ]);
  if (showId != null) {
    return '${AppRoutes.showOverview}/$showId';
  }

  return null;
}

@pragma('vm:entry-point')
const _userPreferencesTable = 'user_preferences';
const _pushSettingsPreferenceKey = 'push_notification_settings';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final backgroundLogger = getLogger('FCMBackgroundHandler');

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    backgroundLogger.i('Handled background push: ${message.messageId}');
  } catch (e, stackTrace) {
    backgroundLogger.e(
        'Failed to initialize background FCM handler', e, stackTrace);
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  static const String _deviceRecordIdKey = 'push.device_record_id';
  static const String _lastTokenKey = 'push.last_known_token';
  static const String _lastUserIdKey = 'push.last_user_id';
  static const String _permissionPromptSeenKey = 'push.permission_prompt_seen';

  final Logger _logger = getLogger('PushNotificationService');
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final AndroidNotificationChannel _androidChannel =
      const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Wird für wichtige Reality-Push-Benachrichtigungen genutzt.',
    importance: Importance.high,
  );

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<AuthState>? _authStateSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;

  bool _isInitialized = false;
  bool _firebaseReady = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    _isInitialized = true;

    await _initializeFirebase();
    if (!_firebaseReady) {
      _isInitialized = false;
      return;
    }

    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _configureLocalNotifications();
      _listenToForegroundMessages();
      _listenToNotificationOpens();
      await _handleInitialMessage();
    }

    await _messaging.setAutoInitEnabled(true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _listenToAuthChanges();
    _listenToTokenRefresh();

    await syncTokenIfPermissionGranted();
  }

  Future<void> _initializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _firebaseReady = true;
      _logger.i('Firebase initialized for push notifications');
    } catch (e, stackTrace) {
      _firebaseReady = false;
      _logger.w(
        'Firebase konnte nicht initialisiert werden. Bitte google-services.json und GoogleService-Info.plist hinterlegen.',
      );
      _logger.e('Firebase init error', e, stackTrace);
    }
  }

  Future<void> _configureLocalNotifications() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) {
          return;
        }

        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            _handleNotificationData(decoded);
          } else if (decoded is Map) {
            _handleNotificationData(decoded.cast<String, dynamic>());
          }
        } catch (e, stackTrace) {
          _logger.e(
              'Failed to parse local notification payload', e, stackTrace);
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  Future<bool> shouldShowPermissionOnboarding() async {
    if (!_firebaseReady) {
      await _initializeFirebase();
    }
    if (!_firebaseReady) {
      return false;
    }

    final platform = PushPlatformMapper.fromTargetPlatform(
      defaultTargetPlatform,
    );
    if (platform == null) {
      return false;
    }

    final settings = await _messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_permissionPromptSeenKey) ?? false);
  }

  Future<void> markPermissionPromptSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionPromptSeenKey, true);
  }

  Future<AuthorizationStatus> requestUserVisiblePermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      _logger.i('Push permission status: ${settings.authorizationStatus.name}');

      if (canSyncTokenForAuthorizationStatus(settings.authorizationStatus)) {
        await _syncTokenForCurrentUser();
      }

      return settings.authorizationStatus;
    } catch (e, stackTrace) {
      _logger.e('Failed to request push permission', e, stackTrace);
      return AuthorizationStatus.notDetermined;
    }
  }

  Future<void> applyUserNotificationPreference(bool enabled) async {
    if (!enabled) {
      await _deactivateCurrentDevice();
      _logger.i('Push notifications disabled in app preferences');
      return;
    }

    final settings = await requestUserVisiblePermission();
    if (canSyncTokenForAuthorizationStatus(settings)) {
      await _syncTokenForCurrentUser();
    }
  }

  Future<void> syncTokenIfPermissionGranted({String? tokenOverride}) async {
    if (!_firebaseReady) {
      await _initializeFirebase();
    }
    if (!_firebaseReady) {
      return;
    }

    final pushEnabledInApp = await _isPushEnabledForCurrentUser();
    if (!pushEnabledInApp) {
      _logger.i('Push notifications are disabled in app settings');
      await _deactivateCurrentDevice();
      return;
    }

    final settings = await _messaging.getNotificationSettings();
    if (!canSyncTokenForAuthorizationStatus(settings.authorizationStatus)) {
      _logger.i('Push permission not granted yet; skipping token sync');
      return;
    }

    await _syncTokenForCurrentUser(tokenOverride: tokenOverride);
  }

  Future<void> openSystemNotificationSettings() async {
    final uri = Uri.parse('app-settings:');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened) {
      _logger.w('Could not open system notification settings');
    }
  }

  void _listenToAuthChanges() {
    _authStateSubscription?.cancel();
    _authStateSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      switch (data.event) {
        case AuthChangeEvent.initialSession:
        case AuthChangeEvent.signedIn:
        case AuthChangeEvent.userUpdated:
        case AuthChangeEvent.tokenRefreshed:
          await syncTokenIfPermissionGranted();
          break;
        case AuthChangeEvent.signedOut:
          await _deactivateCurrentDevice();
          break;
        case AuthChangeEvent.passwordRecovery:
        case AuthChangeEvent.mfaChallengeVerified:
          break;
        default:
          break;
      }
    });
  }

  void _listenToTokenRefresh() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) async {
      await _cacheLastKnownToken(token);
      await syncTokenIfPermissionGranted(tokenOverride: token);
    });
  }

  void _listenToForegroundMessages() {
    _foregroundMessageSubscription?.cancel();
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
      (message) async {
        final notification = message.notification;
        if (notification == null) {
          return;
        }

        if (defaultTargetPlatform == TargetPlatform.iOS) {
          return;
        }

        await _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      },
    );
  }

  void _listenToNotificationOpens() {
    _messageOpenedSubscription?.cancel();
    _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) {
        _handleNotificationData(message.data);
      },
    );
  }

  Future<void> _handleInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotificationData(initialMessage.data);
    });
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    final route = resolvePushRouteFromData(data);
    if (route == null) {
      _logger.i('Push tap received without navigable route: $data');
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        router.go(route);
        _logger.i('Opened push route: $route');
      } catch (e, stackTrace) {
        _logger.e('Failed to open push route $route', e, stackTrace);
      }
    });
  }

  Future<bool> _isPushEnabledForCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return true;
    }

    try {
      final response = await Supabase.instance.client
          .from(_userPreferencesTable)
          .select('preference_value')
          .eq('user_id', user.id)
          .eq('preference_key', _pushSettingsPreferenceKey)
          .maybeSingle();

      final preferences = PushNotificationPreferences.fromPreferenceValue(
        response?['preference_value'],
      );
      return preferences.enabled;
    } catch (e, stackTrace) {
      _logger.w('Failed to read push preferences, defaulting to enabled');
      _logger.e('Push preference lookup error', e, stackTrace);
      return true;
    }
  }

  Future<void> _syncTokenForCurrentUser({String? tokenOverride}) async {
    if (!_firebaseReady) {
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _logger.i('No authenticated user available for push token sync');
      return;
    }

    final platform = PushPlatformMapper.fromTargetPlatform(
      defaultTargetPlatform,
    );
    if (platform == null) {
      _logger
          .i('Current platform is not stored in user_devices; skipping sync');
      return;
    }

    try {
      final token = tokenOverride ?? await _messaging.getToken();
      if (token == null || token.isEmpty) {
        _logger.w('No FCM token available yet');
        return;
      }

      await _cacheLastKnownToken(token);
      await _cacheLastUserId(user.id);

      final payload = buildDeviceTokenPayload(
        deviceRecordId: await _getOrCreateDeviceRecordId(),
        userId: user.id,
        platform: platform,
        fcmToken: token,
      );

      await Supabase.instance.client
          .from('user_devices')
          .upsert(payload, onConflict: 'id');

      _logger.i('FCM token synced for user ${user.id}');
    } catch (e, stackTrace) {
      _logger.e('Failed to sync FCM token', e, stackTrace);
    }
  }

  Future<void> _deactivateCurrentDevice() async {
    if (!_firebaseReady) {
      return;
    }

    final platform = PushPlatformMapper.fromTargetPlatform(
      defaultTargetPlatform,
    );
    if (platform == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final deviceRecordId = prefs.getString(_deviceRecordIdKey);
    final userId = prefs.getString(_lastUserIdKey);
    final cachedToken = prefs.getString(_lastTokenKey);

    if (deviceRecordId == null || userId == null || cachedToken == null) {
      return;
    }

    try {
      final payload = buildDeviceTokenPayload(
        deviceRecordId: deviceRecordId,
        userId: userId,
        platform: platform,
        fcmToken: cachedToken,
        isActive: false,
      );

      await Supabase.instance.client
          .from('user_devices')
          .upsert(payload, onConflict: 'id');

      _logger.i('Marked device as inactive for signed-out user $userId');
    } catch (e, stackTrace) {
      _logger.e('Failed to deactivate current device', e, stackTrace);
    }
  }

  Future<String> _getOrCreateDeviceRecordId() async {
    final prefs = await SharedPreferences.getInstance();
    final existingId = prefs.getString(_deviceRecordIdKey);

    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    const uuid = Uuid();
    final newId = uuid.v4();
    await prefs.setString(_deviceRecordIdKey, newId);
    return newId;
  }

  Future<void> _cacheLastKnownToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastTokenKey, token);
  }

  Future<void> _cacheLastUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUserIdKey, userId);
  }
}
