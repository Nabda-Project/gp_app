import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/reusable/animated_toast.dart';

class NotificationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static OverlayEntry? _overlayEntry;
  static Timer? _timer;

  static void showSuccess({required String title, required String message}) {
    _showToast(title: title, message: message, type: ToastType.success);
  }

  static void showError({required String title, required String message}) {
    _showToast(title: title, message: message, type: ToastType.error);
  }

  static void showWarning({required String title, required String message}) {
    _showToast(title: title, message: message, type: ToastType.warning);
  }

  static void showInfo({required String title, required String message}) {
    _showToast(title: title, message: message, type: ToastType.info);
  }

  /// Show a heads-up notification with sound + haptic feedback.
  /// Used for incoming real-time events (like WhatsApp pop-up).
  static void showHeadsUp({required String title, required String message}) {
    // Play notification sound + haptic
    _playNotificationAlert();
    _showToast(title: title, message: message, type: ToastType.info);
  }

  /// Plays the system notification sound and triggers haptic feedback.
  static void _playNotificationAlert() {
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.mediumImpact();
  }

  static void _showToast({
    required String title,
    required String message,
    required ToastType type,
  }) {
    // Remove existing toast if any
    _removeToast();

    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _overlayEntry = OverlayEntry(
      builder:
          (context) => AnimatedToast(
            title: title,
            message: message,
            type: type,
            onDismiss: _removeToast,
          ),
    );

    overlayState.insert(_overlayEntry!);

    // Auto remove after duration
    _timer = Timer(const Duration(seconds: 4), () {
      _removeToast();
    });
  }

  static void _removeToast() {
    _timer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
