import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/device_reading.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Constants
// ──────────────────────────────────────────────────────────────────────────────

/// Notification channel for the persistent foreground service notification.
const String _kServiceChannelId = 'nabda_health_monitor';
const String _kServiceChannelName = 'Health Monitor';
const String _kServiceChannelDesc =
    'Ongoing notification for health monitoring service';

/// Notification channel for critical health alerts.
const String _kCriticalChannelId = 'nabda_critical_alerts';
const String _kCriticalChannelName = 'Critical Health Alerts';
const String _kCriticalChannelDesc =
    'Urgent notifications for abnormal vital signs';

/// Fixed notification ID for the ongoing service notification.
const int _kServiceNotificationId = 888;

/// UDP port the Nabda device broadcasts on.
const int _kUdpPort = 4210;

/// How often to upload latest reading to backend (seconds).
const int _kUploadIntervalSec = 1;

/// Device considered disconnected after this many seconds without packets.
const int _kDisconnectTimeoutSec = 5;

/// Cooldown between critical notifications of the same type (minutes).
const int _kCriticalCooldownMin = 3;

/// SharedPreferences keys for passing data to the background isolate.
const String _kPrefPatientId = 'bg_patient_id';
const String _kPrefBaseUrl = 'bg_base_url';

/// FlutterSecureStorage key (same as TokenService).
const String _kSecureTokenKey = 'backend_jwt_token';
const String _kSecureEmailKey = 'backend_email';
const String _kSecurePasswordKey = 'backend_password';

// ──────────────────────────────────────────────────────────────────────────────
// Critical thresholds
// ──────────────────────────────────────────────────────────────────────────────

const double _kHrCriticalLow = 40;
const double _kHrCriticalHigh = 150;
const double _kHrWarningLow = 50;
const double _kHrWarningHigh = 120;
const double _kSpo2Critical = 85;
const double _kSpo2Warning = 90;

/// Validation ranges — readings outside these are considered malformed/noise.
const double _kHrMinValid = 20;
const double _kHrMaxValid = 250;
const double _kSpo2MinValid = 50;
const double _kSpo2MaxValid = 100;

// ──────────────────────────────────────────────────────────────────────────────
// HealthMonitorService — public API (runs in main isolate)
// ──────────────────────────────────────────────────────────────────────────────

/// Manages the Android foreground service for background health monitoring.
///
/// **Architecture:**
/// - The foreground service runs Dart code in a **separate isolate**.
/// - It owns the UDP listener, packet parser, backend uploader, and
///   disconnect detector.
/// - The main isolate (UI) communicates with the service via IPC
///   (`invoke` / `on` methods).
/// - The UI never opens a UDP socket — it receives readings from the service.
class HealthMonitorService {
  HealthMonitorService._();

  static final FlutterBackgroundService _service = FlutterBackgroundService();

  /// Initialize the background service configuration.
  /// Call once during app startup (in `main()`).
  /// This does NOT start the service — it only registers it with Android.
  static Future<void> initialize() async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Create the ongoing service notification channel.
    const serviceChannel = AndroidNotificationChannel(
      _kServiceChannelId,
      _kServiceChannelName,
      description: _kServiceChannelDesc,
      importance: Importance.low, // Low = no sound, but persistent
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );

    // Create the critical alerts notification channel.
    const criticalChannel = AndroidNotificationChannel(
      _kCriticalChannelId,
      _kCriticalChannelName,
      description: _kCriticalChannelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      enableLights: true,
    );

    final androidPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidPlugin?.createNotificationChannel(serviceChannel);
    await androidPlugin?.createNotificationChannel(criticalChannel);

    await _service.configure(
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        autoStartOnBoot: false,
        isForegroundMode: true,
        notificationChannelId: _kServiceChannelId,
        initialNotificationTitle: 'Health Monitor',
        initialNotificationContent: 'Preparing…',
        foregroundServiceNotificationId: _kServiceNotificationId,
        foregroundServiceTypes: [AndroidForegroundType.health],
      ),
    );

    log(
      'HealthMonitorService initialized (not started)',
      name: 'HealthMonitorService',
    );
  }

  /// Start the foreground service.
  ///
  /// Stores [patientId], [token], and [baseUrl] in SharedPreferences /
  /// SecureStorage so the background isolate can read them.
  static Future<bool> start({
    required int patientId,
    required String token,
    required String baseUrl,
  }) async {
    // Save params for the background isolate to read.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kPrefPatientId, patientId);
    await prefs.setString(_kPrefBaseUrl, baseUrl);

    // Token is already saved in FlutterSecureStorage by TokenService.
    // We just verify it exists.
    final secureStorage = const FlutterSecureStorage();
    final existingToken = await secureStorage.read(key: _kSecureTokenKey);
    if (existingToken == null || existingToken.isEmpty) {
      // Save the token passed in if SecureStorage is empty.
      await secureStorage.write(key: _kSecureTokenKey, value: token);
    }

    final isRunning = await _service.isRunning();
    if (isRunning) {
      log(
        'Service already running — skipping start',
        name: 'HealthMonitorService',
      );
      return true;
    }

    final started = await _service.startService();
    log('Service start result: $started', name: 'HealthMonitorService');
    return started;
  }

  /// Stop the foreground service.
  static Future<void> stop() async {
    final isRunning = await _service.isRunning();
    if (!isRunning) return;
    _service.invoke('stopService');
    log('Sent stopService command', name: 'HealthMonitorService');
  }

  /// Check if the service is currently running.
  static Future<bool> isRunning() async {
    return await _service.isRunning();
  }

  /// Stream of reading updates from the background service.
  /// Each event is a Map with keys: hr, spo2, battery, connected, timestamp.
  static Stream<Map<String, dynamic>?> get on {
    return _service.on('updateReading');
  }

  /// Stream of service status updates (e.g., authError, stopped).
  static Stream<Map<String, dynamic>?> get onStatus {
    return _service.on('statusUpdate');
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Background isolate entry point
// ──────────────────────────────────────────────────────────────────────────────

/// iOS background fetch handler (not used but required by the package).
@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

/// Main entry point for the background isolate.
/// This runs in a SEPARATE isolate — it cannot access main-isolate singletons.
@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  // Required for plugins to work in background isolate.
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  log('Background service isolate started', name: 'BgService');

  // ── Read configuration ────────────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  final patientId = prefs.getInt(_kPrefPatientId);
  final baseUrl = prefs.getString(_kPrefBaseUrl);

  if (patientId == null || baseUrl == null) {
    log(
      'ERROR: Missing patientId or baseUrl — stopping service',
      name: 'BgService',
    );
    _updateNotification(service, 'Health Monitor', 'Error: login required');
    service.invoke('statusUpdate', {'status': 'authError'});
    await Future.delayed(const Duration(seconds: 2));
    service.stopSelf();
    return;
  }

  final secureStorage = const FlutterSecureStorage();
  String? token = await secureStorage.read(key: _kSecureTokenKey);

  if (token == null || token.isEmpty) {
    log('ERROR: No JWT token — stopping service', name: 'BgService');
    _updateNotification(service, 'Health Monitor', 'Error: login required');
    service.invoke('statusUpdate', {'status': 'authError'});
    await Future.delayed(const Duration(seconds: 2));
    service.stopSelf();
    return;
  }

  log(
    'Config loaded: patientId=$patientId, baseUrl=$baseUrl',
    name: 'BgService',
  );

  // ── State variables ───────────────────────────────────────────────────────
  DeviceReading? latestReading;
  DateTime? lastPacketTime;
  bool deviceConnected = false;
  bool authError = false;

  // Cooldown timestamps for critical notifications (keyed by type).
  final Map<String, DateTime> criticalCooldowns = {};

  // ── Create Dio instance for this isolate ──────────────────────────────────
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ),
  );

  // ── Local notifications plugin for critical alerts ────────────────────────
  final localNotifications = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await localNotifications.initialize(initSettings);

  // ── Start UDP socket ──────────────────────────────────────────────────────
  RawDatagramSocket? udpSocket;
  try {
    udpSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      _kUdpPort,
      reuseAddress: true,
    );
    udpSocket.broadcastEnabled = true;
    log('UDP socket bound on port $_kUdpPort', name: 'BgService');

    _updateNotification(
      service,
      'Health Monitor Running',
      'Listening for Nabda device…',
    );

    udpSocket.listen(
      (RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = udpSocket?.receive();
          if (datagram != null) {
            final message = String.fromCharCodes(datagram.data).trim();
            log('UDP received: $message', name: 'BgService');
            final reading = _parsePacket(message);
            if (reading != null) {
              latestReading = reading;
              lastPacketTime = DateTime.now();
              if (!deviceConnected) {
                deviceConnected = true;
                log(
                  'Device connected. First reading: HR=${reading.heartRate}, SpO2=${reading.spo2}',
                  name: 'BgService',
                );
              }

              // Send to UI immediately.
              service.invoke('updateReading', {
                'hr': reading.heartRate,
                'spo2': reading.spo2,
                'battery': reading.batteryLevel,
                'connected': true,
                'timestamp': reading.timestamp.toIso8601String(),
              });

              // Update notification with latest values.
              _updateNotification(
                service,
                'Health Monitor Running',
                'HR ${reading.heartRate.toStringAsFixed(0)} • SpO₂ ${reading.spo2.toStringAsFixed(0)}%  • Batt ${reading.batteryLevel}%',
              );

              // ── Check for critical values ──
              _checkCritical(reading, localNotifications, criticalCooldowns);
            }
          }
        }
      },
      onError: (error) {
        log('UDP socket error: $error', name: 'BgService');
      },
      onDone: () {
        log('UDP socket closed', name: 'BgService');
      },
    );
  } catch (e) {
    log('Failed to bind UDP socket: $e', name: 'BgService');
    _updateNotification(
      service,
      'Health Monitor',
      'Error: could not start listener',
    );
    service.invoke('statusUpdate', {'status': 'udpError', 'message': '$e'});
    await Future.delayed(const Duration(seconds: 2));
    service.stopSelf();
    return;
  }

  // ── Device disconnect checker (every 3 seconds) ───────────────────────────
  Timer.periodic(const Duration(seconds: 3), (timer) {
    if (lastPacketTime != null) {
      final elapsed = DateTime.now().difference(lastPacketTime!).inSeconds;
      if (elapsed >= _kDisconnectTimeoutSec && deviceConnected) {
        deviceConnected = false;
        log(
          'Device disconnected (no packets for ${elapsed}s)',
          name: 'BgService',
        );
        _updateNotification(
          service,
          'Health Monitor Running',
          'Device disconnected',
        );
        service.invoke('updateReading', {
          'hr': 0.0,
          'spo2': 0.0,
          'battery': 0,
          'connected': false,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    }
  });

  // ── Backend upload timer (every 1 second) ────────────────────────────────
  // Async closure captures outer-scope state. Timer fires every second;
  // each tick is fire-and-forget so slow requests don't stack up.
  bool _uploading = false; // debounce: skip if previous upload still in-flight

  Timer.periodic(const Duration(seconds: _kUploadIntervalSec), (_) async {
    if (_uploading || authError || !deviceConnected || latestReading == null) {
      return;
    }
    _uploading = true;

    final reading = latestReading!;
    try {
      final response = await dio.post(
        '/iot/upload/$patientId',
        data: {
          'heartRate': reading.heartRate,
          'spo2': reading.spo2,
          'batteryLevel': reading.batteryLevel,
        },
      );
      log(
        'Uploaded reading (status=${response.statusCode})',
        name: 'BgService',
      );

      // ── Push backend response to UI immediately ──────────────────────
      if (response.data != null && response.data is Map) {
        service.invoke('metricUpdate', response.data as Map<String, dynamic>);
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      log('Upload failed: status=$statusCode, ${e.message}', name: 'BgService');

      if (statusCode == 401 || statusCode == 403) {
        final refreshed = await _tryRefreshToken(dio, secureStorage, baseUrl);
        if (refreshed) {
          final newToken = await secureStorage.read(key: _kSecureTokenKey);
          if (newToken != null) {
            dio.options.headers['Authorization'] = 'Bearer $newToken';
            token = newToken;
            log('Token refreshed in background service', name: 'BgService');
          }
        } else {
          authError = true;
          _updateNotification(
            service,
            'Health Monitor',
            'Login required — upload paused',
          );
          service.invoke('statusUpdate', {'status': 'authError'});
          log('Auth failed — uploads paused', name: 'BgService');
        }
      } else {
        // Non-auth error — notify UI that server may be unreachable.
        service.invoke('statusUpdate', {
          'status': 'uploadError',
          'code': statusCode ?? 0,
        });
      }
    } catch (e) {
      log('Upload error: $e', name: 'BgService');
    } finally {
      _uploading = false;
    }
  });

  // ── Listen for stop command from main isolate ─────────────────────────────
  service.on('stopService').listen((event) {
    log('Received stopService command — shutting down', name: 'BgService');
    udpSocket?.close();
    service.stopSelf();
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// Helper functions (run in background isolate)
// ──────────────────────────────────────────────────────────────────────────────

/// Update the foreground service notification text.
void _updateNotification(ServiceInstance service, String title, String body) {
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(title: title, content: body);
  }
}

/// Parse a raw UDP packet into a [DeviceReading], or `null` if malformed.
///
/// Expected format:
///   `MAX30105_reading: 97.50 | PULSE_reading: 72.30 | Batt: 200`
///
/// **Sensor mapping:**
/// - `PULSE_reading`    → Heart Rate (BPM) from analog Pulse Sensor
/// - `MAX30105_reading` → Heart Rate (BPM) from MAX30105 IR beat detection
///   (mapped to the `spo2` field — NOT real SpO2; see firmware notes)
///
/// **Battery conversion:**
/// `Batt` is a raw ADC value from ADC0832, range 0–255.
/// Converted to percentage using LiPo voltage curve:
///   voltage = (raw / 255.0) * 4.2
///   percentage = ((voltage - 3.0) / 1.2 * 100).clamp(0, 100)
DeviceReading? _parsePacket(String message) {
  try {
    final maxRegex = RegExp(r'MAX30105_reading:\s*([\d.]+)');
    final pulseRegex = RegExp(r'PULSE_reading:\s*([\d.]+)');
    final battRegex = RegExp(r'Batt:\s*(\d+)');

    final maxMatch = maxRegex.firstMatch(message);
    final pulseMatch = pulseRegex.firstMatch(message);
    final battMatch = battRegex.firstMatch(message);

    if (maxMatch == null || pulseMatch == null || battMatch == null) {
      log('Could not parse all fields from: $message', name: 'BgService');
      return null;
    }

    final max30105Reading = double.tryParse(maxMatch.group(1)!);
    final pulseReading = double.tryParse(pulseMatch.group(1)!);
    final battRaw = int.tryParse(battMatch.group(1)!);

    if (max30105Reading == null || pulseReading == null || battRaw == null) {
      log('Could not parse numeric values from: $message', name: 'BgService');
      return null;
    }

    // ── Battery conversion ──
    // Batt is a raw ADC0832 value (0–255).
    // LiPo assumption: 3.0V (0%) → 4.2V (100%).
    // ADC0832 maps 0–4.2V linearly to 0–255.
    final voltage = battRaw / 255.0 * 4.2;
    final batteryPct = ((voltage - 3.0) / 1.2 * 100).clamp(0, 100).toInt();

    // ── Validation ──
    if (pulseReading < _kHrMinValid || pulseReading > _kHrMaxValid) {
      log(
        'HR out of valid range ($pulseReading) — discarding',
        name: 'BgService',
      );
      return null;
    }
    if (max30105Reading < _kSpo2MinValid || max30105Reading > _kSpo2MaxValid) {
      log(
        'SpO2 out of valid range ($max30105Reading) — discarding',
        name: 'BgService',
      );
      return null;
    }

    return DeviceReading(
      heartRate: pulseReading,
      spo2: max30105Reading,
      batteryLevel: batteryPct,
      timestamp: DateTime.now(),
    );
  } catch (e) {
    log('Error parsing packet "$message": $e', name: 'BgService');
    return null;
  }
}

/// Check if a reading has critical values and fire a local notification
/// if the cooldown has expired.
void _checkCritical(
  DeviceReading reading,
  FlutterLocalNotificationsPlugin notifications,
  Map<String, DateTime> cooldowns,
) {
  final now = DateTime.now();

  // ── Heart Rate ──
  if (reading.heartRate < _kHrCriticalLow ||
      reading.heartRate > _kHrCriticalHigh) {
    _fireCriticalNotification(
      notifications: notifications,
      cooldowns: cooldowns,
      type: 'critical_hr',
      title: '⚠️ Critical Heart Rate',
      body: 'Heart rate is ${reading.heartRate.toStringAsFixed(0)} bpm',
      now: now,
    );
  } else if (reading.heartRate < _kHrWarningLow ||
      reading.heartRate > _kHrWarningHigh) {
    _fireCriticalNotification(
      notifications: notifications,
      cooldowns: cooldowns,
      type: 'warning_hr',
      title: '⚠️ Abnormal Heart Rate',
      body: 'Heart rate is ${reading.heartRate.toStringAsFixed(0)} bpm',
      now: now,
    );
  }

  // ── SpO2 ──
  if (reading.spo2 < _kSpo2Critical) {
    _fireCriticalNotification(
      notifications: notifications,
      cooldowns: cooldowns,
      type: 'critical_spo2',
      title: '🔴 Low Oxygen',
      body: 'SpO₂ is ${reading.spo2.toStringAsFixed(0)}%',
      now: now,
    );
  } else if (reading.spo2 < _kSpo2Warning) {
    _fireCriticalNotification(
      notifications: notifications,
      cooldowns: cooldowns,
      type: 'warning_spo2',
      title: '⚠️ Low Oxygen',
      body: 'SpO₂ is ${reading.spo2.toStringAsFixed(0)}%',
      now: now,
    );
  }
}

/// Fire a critical local notification if the cooldown for [type] has expired.
void _fireCriticalNotification({
  required FlutterLocalNotificationsPlugin notifications,
  required Map<String, DateTime> cooldowns,
  required String type,
  required String title,
  required String body,
  required DateTime now,
}) {
  final lastFired = cooldowns[type];
  if (lastFired != null &&
      now.difference(lastFired).inMinutes < _kCriticalCooldownMin) {
    return; // Still in cooldown.
  }

  cooldowns[type] = now;

  final androidDetails = AndroidNotificationDetails(
    _kCriticalChannelId,
    _kCriticalChannelName,
    channelDescription: _kCriticalChannelDesc,
    importance: Importance.max,
    priority: Priority.max,
    playSound: true,
    enableVibration: true,
    icon: '@mipmap/ic_launcher',
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
    autoCancel: true,
    showWhen: true,
    enableLights: true,
    ticker: '$title: $body',
    styleInformation: BigTextStyleInformation(
      body,
      contentTitle: title,
      summaryText: 'NABDA Health Alert',
    ),
  );

  notifications.show(
    // Unique but deterministic per type so updates overwrite previous.
    type.hashCode % 2147483647,
    title,
    body,
    NotificationDetails(android: androidDetails),
  );

  log('Critical notification fired: $type — $title', name: 'BgService');
}

/// Try to re-authenticate using stored credentials (email/password).
/// Returns `true` if token was refreshed successfully.
Future<bool> _tryRefreshToken(
  Dio dio,
  FlutterSecureStorage secureStorage,
  String baseUrl,
) async {
  try {
    final email = await secureStorage.read(key: _kSecureEmailKey);
    final password = await secureStorage.read(key: _kSecurePasswordKey);

    if (email == null || password == null) {
      log('No stored credentials for token refresh', name: 'BgService');
      return false;
    }

    // Use a fresh Dio without the expired token for login.
    final loginDio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    final response = await loginDio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    if (response.statusCode == 200 && response.data != null) {
      final newToken = response.data['token'] as String?;
      if (newToken != null && newToken.isNotEmpty) {
        await secureStorage.write(key: _kSecureTokenKey, value: newToken);
        log('Token refreshed via re-login', name: 'BgService');
        return true;
      }
    }
  } catch (e) {
    log('Token refresh failed: $e', name: 'BgService');
  }
  return false;
}
