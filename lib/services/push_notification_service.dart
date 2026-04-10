import 'dart:developer';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/api/api_endpoints.dart';
import '../core/api/dio_client.dart';
import '../firebase_options.dart';
import 'notification_service.dart';
import 'storage_service.dart';

/// Top-level background handler — MUST be a top-level function (not a method).
/// Called when the app is in the background OR terminated.
/// NOTE: When sending notification+data payload, Android auto-displays the
/// notification in background/terminated state, so we do NOT show another one here.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background isolate
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  log('FCM background: received message type=${message.data['type']}',
      name: 'PushNotificationService');
  // Android system already displays the notification from the
  // `notification` payload — no need to show a local notification.
}

/// Service responsible for all Firebase Cloud Messaging (FCM) push notifications.
///
/// Handles:
/// - Permission requests
/// - Token registration with backend
/// - Foreground message display
/// - Background message display
/// - Notification tap navigation
class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Android notification channel for HealthSync — high importance + default sound.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'healthsync_notifications',
    'HealthSync Notifications',
    description: 'Notifications for messages, appointments, and system events',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  /// Initialize FCM, permissions, and local notification display.
  /// Call once after Firebase.initializeApp() and user login.
  static Future<void> initialize() async {
    if (_initialized) return;

    // 1. Request permissions (Android 13+ and iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    log('FCM permission status: ${settings.authorizationStatus}',
        name: 'PushNotificationService');

    // 2. Create the Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3. Initialize flutter_local_notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 4. Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Handle foreground messages — show local notification since Android
    //    does NOT auto-display notifications when the app is in the foreground.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6. Ensure foreground notifications show as system notifications (iOS)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 7. Handle notification taps when app was terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationNavigation(initialMessage.data);
    }

    // 8. Handle notification taps when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationNavigation(message.data);
    });

    // 9. Get and register FCM token
    await _registerToken();

    // 10. Listen for token refreshes
    _messaging.onTokenRefresh.listen((newToken) {
      _sendTokenToBackend(newToken);
    });

    _initialized = true;
    log('PushNotificationService initialized', name: 'PushNotificationService');
  }

  /// Get the FCM token and send it to the backend.
  static Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        log('FCM token obtained: ${token.substring(0, 20)}...',
            name: 'PushNotificationService');
        await _sendTokenToBackend(token);
      } else {
        log('FCM token is null!', name: 'PushNotificationService');
      }
    } catch (e) {
      log('Failed to get FCM token: $e', name: 'PushNotificationService');
    }
  }

  /// Send the FCM token to the backend.
  static Future<void> _sendTokenToBackend(String token) async {
    try {
      await DioClient.instance.put(
        ApiEndpoints.updateFcmToken,
        data: {'token': token},
      );
      log('FCM token registered with backend', name: 'PushNotificationService');
    } catch (e) {
      log('Failed to send FCM token to backend: $e',
          name: 'PushNotificationService');
    }
  }

  /// Handle foreground FCM messages.
  /// Android does NOT auto-show the notification when the app is in foreground,
  /// so we must create a local notification manually.
  static void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final title = message.notification?.title ?? data['title'] ?? 'HealthSync';
    final body = message.notification?.body ?? data['body'] ?? '';

    log('FCM foreground: showing local notification — title=$title',
        name: 'PushNotificationService');

    // Show a system-level local notification with sound
    _showLocalNotification(
      title: title,
      body: body,
      payload: jsonEncode(data),
    );
  }

  /// Show a local notification with sound using flutter_local_notifications.
  /// Appears as a heads-up banner on top of any app + in the system notification tray.
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'healthsync_notifications',
      'HealthSync Notifications',
      channelDescription:
          'Notifications for messages, appointments, and system events',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      autoCancel: true,
      // Heads-up: ensures the notification appears as a banner over other apps
      fullScreenIntent: true,
      ticker: '$title: $body',
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'HealthSync',
      ),
    );

    final details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique ID
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Handle notification tap — navigate to relevant screen.
  static void _onNotificationTapped(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _handleNotificationNavigation(data);
    } catch (e) {
      log('Failed to parse notification payload: $e',
          name: 'PushNotificationService');
    }
  }

  /// Navigate based on notification data type.
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    if (type == null) return;

    final navigatorState = NotificationService.navigatorKey.currentState;
    if (navigatorState == null) return;

    if (type == 'CHAT') {
      final relatedId = int.tryParse(data['relatedId']?.toString() ?? '');
      final relatedName = data['relatedName'] as String?;
      if (relatedId != null) {
        navigatorState.pushNamed(
          '/doctor_chat',
          arguments: {
            'doctorName': relatedName,
            'doctorId': relatedId,
          },
        );
      }
    } else if (type.startsWith('APPOINTMENT')) {
      // Navigate to appointments screen
      final user = StorageService.getUser();
      if (user?.role == 'DOCTOR') {
        navigatorState.pushNamed('/doctor_appointments');
      }
      // Patients see appointments on their dashboard already
    }
  }
}
