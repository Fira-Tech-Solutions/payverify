import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../api/api_client.dart';
import '../local_db/local_db.dart';
import '../../models/transaction.dart';

/// Handles the case where the cashier verifies a payment but has no internet.
/// Queues the verification request and replays it when connectivity returns.
class OfflineSyncManager {
  static const _queueBox = 'offline_queue';

  static final OfflineSyncManager _i = OfflineSyncManager._();
  factory OfflineSyncManager() => _i;
  OfflineSyncManager._();

  Box<String>? _box;
  Timer? _syncTimer;
  bool _isSyncing = false;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_queueBox);
    _startPeriodicSync();
  }

  // ─── Queue a verification attempt made while offline ──────────────

  Future<void> queueVerification(String referenceCode) async {
    final entry = jsonEncode({
      'referenceCode': referenceCode,
      'timestamp':     DateTime.now().toIso8601String(),
      'businessId':    localDb.getUser()?.businessId,
      'workerId':      localDb.getUser()?.id,
    });
    await _box?.add(entry);
    debugPrint('[Offline] Queued verification: $referenceCode');
  }

  // ─── Replay queue when back online ───────────────────────────────

  Future<void> syncNow() async {
    if (_isSyncing || (_box?.isEmpty ?? true)) return;
    _isSyncing = true;

    final keys   = _box!.keys.toList();
    final failed = <dynamic>[];

    for (final key in keys) {
      final raw = _box!.get(key);
      if (raw == null) continue;

      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        await api.verifyTransaction(data['referenceCode'] as String);
        await _box!.delete(key);
        debugPrint('[Offline] Replayed: ${data['referenceCode']}');
      } catch (e) {
        debugPrint('[Offline] Replay failed for $key: $e');
        failed.add(key);
      }
    }

    // If nothing left in queue after sync, pull fresh list from server
    if (_box!.isEmpty) {
      try {
        await api.syncTransactions();
      } catch (_) {}
    }

    _isSyncing = false;
    debugPrint('[Offline] Sync done. Failed: ${failed.length}');
  }

  int get queueLength => _box?.length ?? 0;

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 2), (_) => syncNow());
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}

final offlineSync = OfflineSyncManager();
