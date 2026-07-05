import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart';
import '../models/transaction.dart';
import '../services/realtime/realtime_service.dart';

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  (ref) => NotificationsNotifier(),
);

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  NotificationsNotifier() : super([]) {
    realtimeService.onTransaction(_onTransaction);
  }

  void _onTransaction(Transaction tx) {
    add(
      AppNotification(
        id: tx.id,
        title: 'New Transaction',
        body:
            'ETB ${tx.amount.toStringAsFixed(2)} via ${tx.paymentMethod}',
        type: AppNotificationType.transaction,
        createdAt: tx.timestamp,
      ),
    );
  }

  void add(AppNotification n) {
    state = [n, ...state];
  }

  void markRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n..isRead = true else n,
    ];
  }

  void markAllRead() {
    state = [
      for (final n in state)
        n..isRead = true,
    ];
  }

  int get unreadCount => state.where((n) => !n.isRead).length;
}
