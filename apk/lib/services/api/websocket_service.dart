import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../models/transaction.dart';
import '../local_db/local_db.dart';

/// Connects to your backend WebSocket endpoint.
/// Backend pushes new PENDING transactions as they arrive from bank SMS.
/// Cashier app receives them instantly — no polling needed.
class WebSocketService {
  static const _wsUrl = 'ws://192.168.100.131:3000/ws';

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  bool _isConnected = false;
  int _retryCount = 0;
  static const _maxRetries = 5;

  // Callbacks
  Function(Transaction tx)? onNewTransaction;
  Function(String txId, String status)? onStatusUpdate;
  Function(bool connected)? onConnectionChange;
  Function(String tier, String endsAt)? onSubscriptionActivated;

  // ── Connect ──────────────────────────────────────────────────────

  Future<void> connect() async {
    final token = localDb.getToken();
    final user  = localDb.getUser();
    if (token == null || user == null) return;

    // Close any existing connection first
    _pingTimer?.cancel();
    await _sub?.cancel();
    _sub = null;
    await _channel?.sink.close();
    _channel = null;

    try {
      final uri = Uri.parse(
        '$_wsUrl?token=$token&businessId=${user.businessId}',
      );
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _isConnected = true;
      _retryCount = 0;
      onConnectionChange?.call(true);
      debugPrint('[WS] Connected');

      _sub = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      // Ping every 30s to keep connection alive
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _send({'type': 'ping'});
      });
    } catch (e) {
      debugPrint('[WS] Connection failed: $e');
      _scheduleReconnect();
    }
  }

  void disconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    onConnectionChange?.call(false);
    debugPrint('[WS] Disconnected');
  }

  // ── Message handling ──────────────────────────────────────────────

  void _onMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'new_transaction':
          final tx = Transaction.fromJson(
              data['transaction'] as Map<String, dynamic>);
          localDb.saveTransaction(tx);
          onNewTransaction?.call(tx);
          debugPrint('[WS] New transaction: ${tx.transactionId}');
          break;

        case 'status_update':
          final txId   = data['transactionId'] as String;
          final status = data['status'] as String;
          localDb.updateStatus(txId, status);
          onStatusUpdate?.call(txId, status);
          debugPrint('[WS] Status update: $txId → $status');
          break;

        case 'pong':
          // Keep-alive confirmed
          break;

        case 'subscription_activated':
          final tier = data['tier'] as String? ?? '';
          final endsAt = data['endsAt'] as String? ?? '';
          onSubscriptionActivated?.call(tier, endsAt);
          debugPrint('[WS] Subscription activated: $tier until $endsAt');
          break;

        default:
          debugPrint('[WS] Unknown message type: $type');
      }
    } catch (e) {
      debugPrint('[WS] Failed to parse message: $e');
    }
  }

  void _onError(Object error) {
    debugPrint('[WS] Error: $error');
    _isConnected = false;
    onConnectionChange?.call(false);
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('[WS] Connection closed');
    _isConnected = false;
    onConnectionChange?.call(false);
    _scheduleReconnect();
  }

  // ── Send ──────────────────────────────────────────────────────────

  void _send(Map<String, dynamic> data) {
    if (!_isConnected || _channel == null) return;
    try {
      _channel!.sink.add(jsonEncode(data));
    } catch (e) {
      debugPrint('[WS] Send failed: $e');
    }
  }

  // ── Reconnect logic (exponential backoff) ─────────────────────────

  void _scheduleReconnect() {
    if (_retryCount >= _maxRetries) {
      debugPrint('[WS] Max retries reached — giving up');
      return;
    }
    final delay = Duration(seconds: (2 << _retryCount).clamp(2, 60));
    _retryCount++;
    debugPrint('[WS] Reconnecting in ${delay.inSeconds}s (attempt $_retryCount)');
    _reconnectTimer = Timer(delay, connect);
  }

  bool get isConnected => _isConnected;
}

// Singleton
final wsService = WebSocketService();
