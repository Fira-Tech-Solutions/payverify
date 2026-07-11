import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription.dart';
import '../services/api/api_client.dart';
import '../providers/notifications_provider.dart';

// ─── Subscription Status ─────────────────────────────────────────────────────
final subscriptionProvider =
    FutureProvider<SubscriptionStatus>((ref) => api.getSubscriptionStatus());

// ─── Subscription Plans ──────────────────────────────────────────────────────
final subscriptionPlansProvider =
    FutureProvider<List<SubscriptionPlan>>((ref) => api.getSubscriptionPlans());

// ─── Subscription Payment History ────────────────────────────────────────────
final subscriptionHistoryProvider =
    FutureProvider<List<SubscriptionPayment>>(
        (ref) => api.getSubscriptionHistory());

// ─── TeleBirr order status polling ──────────────────────────────────────────
final telebirrOrderProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, outTradeNo) async {
  return api.getOrderStatus(outTradeNo);
});

// ─── Subscription Banner ─────────────────────────────────────────────────────
final subscriptionBannerProvider = Provider<SubscriptionBannerInfo?>((ref) {
  final sub = ref.watch(subscriptionProvider);
  return sub.whenOrNull(
    data: (status) {
      // Trigger subscription expiry notifications via notificationsProvider
      ref.read(notificationsProvider.notifier).checkSubscriptionAndNotify(
        isTrial: status.isTrial,
        isGrace: status.isGrace,
        isExpired: status.isExpired,
        daysRemaining: status.daysRemaining,
        graceDaysRemaining: status.graceDaysRemaining,
      );

      if (status.isTrial && (status.daysRemaining ?? 99) <= 3) {
        return SubscriptionBannerInfo(
          type: SubscriptionBannerType.trial,
          message: '${status.daysRemaining} days left in trial',
          daysLeft: status.daysRemaining,
        );
      }
      if (status.isGrace) {
        return SubscriptionBannerInfo(
          type: SubscriptionBannerType.grace,
          message:
              'Subscription expired — ${status.graceDaysRemaining} days to renew',
          daysLeft: status.graceDaysRemaining,
        );
      }
      if (status.isExpired) {
        return SubscriptionBannerInfo(
          type: SubscriptionBannerType.expired,
          message: 'Subscription expired — renew to continue',
          daysLeft: 0,
        );
      }
      return null;
    },
  );
});

enum SubscriptionBannerType { trial, grace, expired }

class SubscriptionBannerInfo {
  final SubscriptionBannerType type;
  final String message;
  final int? daysLeft;

  SubscriptionBannerInfo({
    required this.type,
    required this.message,
    this.daysLeft,
  });
}