import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
import '../models/notification.dart';
import '../models/transaction.dart';
import '../services/realtime/realtime_service.dart';

// ─── Preferences ──────────────────────────────────────────────────────────────
const _prefNotificationsEnabled = 'notifications_enabled';
const _prefInAppNotifications = 'in_app_notifications';
const _prefLastTrialWarning = 'last_trial_warning_day';
const _prefLastGraceWarning = 'last_grace_warning_day';

// ─── Notification channel ─────────────────────────────────────────────────────
const _channelId = 'payverify_subscription';
const _channelName = 'Subscription Alerts';
const _channelDesc = 'Notifications about subscription status';

const _trialWarning3dId = 1001;
const _trialWarning1dId = 1002;
const _trialExpiredId = 1003;
const _graceWarningId = 1004;
const _expiredId = 1005;

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  (ref) => NotificationsNotifier(),
);

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  NotificationsNotifier() : super([]) {
    _init();
    realtimeService.onTransaction(_onTransaction);
  }

  Future<void> _init() async {
    // Load persisted notifications
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_prefInAppNotifications) ?? [];
    state = jsonList
        .map((e) => AppNotification.fromString(e))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Initialize flutter_local_notifications
    if (!_initialized) {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      _initialized = true;
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    log('[Notifications] Tapped: ${response.payload}');
  }

  // ─── Preferences ────────────────────────────────────────────────────────────

  Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefNotificationsEnabled, enabled);
    if (!enabled) {
      await _localNotifications.cancelAll();
    }
    log('[Notifications] Notifications ${enabled ? "enabled" : "disabled"}');
  }

  // ─── Realtime transaction notifications ──────────────────────────────────────

  void _onTransaction(Transaction tx) {
    add(
      AppNotification(
        id: tx.id,
        title: 'New Transaction',
        body: 'ETB ${tx.amount.toStringAsFixed(2)} via ${tx.paymentMethod}',
        type: AppNotificationType.transaction,
        createdAt: tx.timestamp,
      ),
    );
  }

  // ─── Core mutations ─────────────────────────────────────────────────────────

  void add(AppNotification n) {
    state = [n, ...state];
    _persistAndSchedule(n);
  }

  void markRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n..isRead = true else n,
    ];
    _persistState();
  }

  void markAllRead() {
    state = [
      for (final n in state)
        n..isRead = true,
    ];
    _persistState();
  }

  int get unreadCount => state.where((n) => !n.isRead).length;

  // ─── Persistence ────────────────────────────────────────────────────────────

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = state.map((e) => e.toString()).toList();
    // Keep max 50
    if (jsonList.length > 50) jsonList.removeRange(0, jsonList.length - 50);
    await prefs.setStringList(_prefInAppNotifications, jsonList);
  }

  Future<void> _persistAndSchedule(AppNotification n) async {
    await _persistState();
    if (n.type == AppNotificationType.subscription) {
      _showPushNotification(n);
    }
  }

  // ─── Push notifications (flutter_local_notifications) ────────────────────────

  Future<void> _showPushNotification(AppNotification n) async {
    if (!await isNotificationsEnabled()) return;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF276B47),
      styleInformation: BigTextStyleInformation(n.body),
    );

    final details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      n.id.hashCode,
      n.title,
      n.body,
      details,
      payload: n.id,
    );
    log('[Notifications] Push shown: ${n.title}');
  }

  // ─── Subscription expiry notifications ──────────────────────────────────────

  /// Call this from subscriptionBannerProvider or on app foreground
  Future<void> checkSubscriptionAndNotify({
    required bool isTrial,
    required bool isGrace,
    required bool isExpired,
    int? daysRemaining,
    int? graceDaysRemaining,
  }) async {
    if (!await isNotificationsEnabled()) return;
    if (!_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';

    // ── Trial warnings ────────────────────────────────────────────────────
    if (isTrial && daysRemaining != null) {
      if (daysRemaining <= 1) {
        final lastShown = prefs.getString(_prefLastTrialWarning);
        if (lastShown != today) {
          add(
            AppNotification(
              id: 'sub_trial_expired_$today',
              title: 'Trial Ending Today',
              body: 'Your free trial ends today. Upgrade now to keep verifying payments.',
              type: AppNotificationType.subscription,
              createdAt: now,
            ),
          );
          await prefs.setString(_prefLastTrialWarning, today);
        }
      } else if (daysRemaining <= 3) {
        final lastShown = prefs.getString(_prefLastTrialWarning);
        if (lastShown != today) {
          add(
            AppNotification(
              id: 'sub_trial_warning_$today',
              title: 'Trial Expiring Soon',
              body: 'Only $daysRemaining days left in your free trial. Upgrade to avoid interruptions.',
              type: AppNotificationType.subscription,
              createdAt: now,
            ),
          );
          await prefs.setString(_prefLastTrialWarning, today);
        }
      }
    }

    // ── Grace period warning ──────────────────────────────────────────────
    if (isGrace && graceDaysRemaining != null) {
      final lastShown = prefs.getString(_prefLastGraceWarning);
      if (lastShown != today) {
        add(
          AppNotification(
            id: 'sub_grace_warning_$today',
            title: 'Subscription Grace Period',
            body: 'Your subscription expired. You have $graceDaysRemaining days to renew before service stops.',
            type: AppNotificationType.subscription,
            createdAt: now,
          ),
        );
        await prefs.setString(_prefLastGraceWarning, today);
      }
    }

    // ── Fully expired ─────────────────────────────────────────────────────
    if (isExpired) {
      final lastShown = prefs.getString(_prefLastGraceWarning);
      if (lastShown != today) {
        add(
          AppNotification(
            id: 'sub_expired_$today',
            title: 'Subscription Expired',
            body: 'Your subscription has expired. Renew now to continue verifying payments.',
            type: AppNotificationType.subscription,
            createdAt: now,
          ),
        );
        await prefs.setString(_prefLastGraceWarning, today);
      }
    }
  }
}