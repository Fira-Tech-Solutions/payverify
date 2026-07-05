import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Gives haptic + audio feedback when a payment is verified or rejected.
/// No external notification package needed — uses Flutter's built-in
/// HapticFeedback and the system vibrator.
class NotificationService {
  static const _vibrator = MethodChannel('payverify/vibrator');

  /// Call this when a payment is confirmed ✓
  static Future<void> paymentVerified() async {
    // Double short buzz — feels like "yes yes"
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.mediumImpact();
  }

  /// Call this when a payment fails / mismatches ✗
  static Future<void> paymentFailed() async {
    // Single long heavy buzz — feels like "no"
    await HapticFeedback.heavyImpact();
  }

  /// Call this when a new bank SMS arrives in background (Android)
  static Future<void> newTransactionArrived() async {
    await HapticFeedback.lightImpact();
  }
}
