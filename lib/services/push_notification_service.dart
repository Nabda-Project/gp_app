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
import 'token_service.dart';

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
  
  // Create a new instance of FlutterLocalNotificationsPlugin for the background isolate
  final localNotifications = FlutterLocalNotificationsPlugin();
  
  // Initialize it for the background isolate
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await localNotifications.initialize(initSettings);

  final data = message.data;
  final title = data['title'] ?? 'HealthSync';
  final rawBody = data['body'] ?? '';

  // Explicitly add sender name to the body content
  final body = (title != 'HealthSync' && title.isNotEmpty) 
      ? '$title: $rawBody' 
      : rawBody;

  final androidDetails = AndroidNotificationDetails(
    'healthsync_alerts_v4',
    'HealthSync Alerts',
    channelDescription: 'Important alerts for messages, appointments, and health events',
    importance: Importance.max,
    priority: Priority.max,
    playSound: true,
    enableVibration: true,
    icon: '@mipmap/ic_launcher',
    category: AndroidNotificationCategory.message,
    visibility: NotificationVisibility.public,
    autoCancel: true,
    showWhen: true,
    enableLights: true,
    ticker: '$title: $body',
    styleInformation: BigTextStyleInformation(
      body,
      contentTitle: title,
      summaryText: 'HealthSync',
    ),
  );

  final details = NotificationDetails(android: androidDetails);

  await localNotifications.show(
    DateTime.now().millisecondsSinceEpoch % 2147483647, // unique ID
    title,
    body,
    details,
    payload: jsonEncode(data),
  );
}

/// Service responsible for all Firebase Cloud Messaging (FCM) push notifications.
///
/// Handles:
/// - Permission requests
/// - Token registration with backend
/// - Foreground message display (system heads-up notification like WhatsApp)
/// - Background message display
/// - Notification tap navigation
class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// New channel ID — Android caches channel settings forever, so we use a
  /// fresh ID to guarantee MAX importance + heads-up display.
  static const String _channelId = 'healthsync_alerts_v4';
  static const String _channelName = 'HealthSync Alerts';
  static const String _channelDesc =
      'Important alerts for messages, appointments, and health events';

  /// Android notification channel — MAX importance for heads-up banners.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDesc,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
    enableLights: true,
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

    // 2. Create the Android notification channel (MAX importance)
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      try {
        await androidPlugin.createNotificationChannel(_channel);
        // Request exact alarm / full-screen intent permission (Android 14+)
        await androidPlugin.requestExactAlarmsPermission();
        await androidPlugin.requestNotificationsPermission();
      } catch (e) {
        log('Error requesting Android notification permissions: $e',
            name: 'PushNotificationService');
      }
    }

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

    // 5. Handle foreground messages — show system heads-up notification
    //    Android does NOT auto-display notifications when the app is in foreground.
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
      final hasToken = await TokenService.hasToken();
      if (!hasToken) {
        log('Skipping FCM backend registration: user is not logged in.',
            name: 'PushNotificationService');
        return;
      }

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
  /// so we create a LOCAL SYSTEM notification that appears as a heads-up banner
  /// on top of whatever app is open — exactly like WhatsApp.
  static void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final title = message.notification?.title ?? data['title'] ?? 'HealthSync';
    final rawBody = message.notification?.body ?? data['body'] ?? '';
    
    // Explicitly add sender name to the body content to guarantee it's visible
    final body = (title != 'HealthSync' && title.isNotEmpty) 
        ? '$title: $rawBody' 
        : rawBody;

    log('FCM foreground: showing heads-up system notification — title=$title',
        name: 'PushNotificationService');

    // Show a real system heads-up notification (NOT an in-app toast)
    showHeadsUpNotification(
      title: title,
      body: body,
      payload: jsonEncode(data),
    );
  }

  /// Show a REAL system heads-up notification that appears as a banner on top
  /// of ANY app — exactly like WhatsApp, Telegram, etc.
  ///
  /// This uses flutter_local_notifications to create a high-priority
  /// notification with fullScreenIntent which triggers the heads-up display.
  ///
  /// Can be called from anywhere in the app (dashboard, chat service, etc.)
  static Future<void> showHeadsUpNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      // ── These together guarantee heads-up banner ──
      importance: Importance.max,
      priority: Priority.max,
      // ── Sound & vibration ──
      playSound: true,
      enableVibration: true,
      // ── Visual ──
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.message,
      visibility: NotificationVisibility.public,
      autoCancel: true,
      showWhen: true,
      enableLights: true,
      ticker: '$title: $body',
      // ── Expanded text style ──
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'HealthSync',
      ),
    );

    final details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 2147483647, // unique ID per message
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
