import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../local_db/local_db.dart';
import '../../models/transaction.dart';

/// Maintains a persistent WebSocket connection to the backend.
/// When a new bank SMS is processed server-side (e.g. via Africa's Talking
/// SMS gateway), the backend pushes the transaction to all connected
/// devices for that business — so all cashier terminals update instantly.
class RealtimeService {
  static const _wsBase = 'ws://192.168.100.131:3000/ws';

  static final RealtimeService _instance = RealtimeService._();
  factory RealtimeService() => _instance;
  RealtimeService._();

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  bool _connected = false;
  int _retryCount = 0;
  static const _maxRetries = 10;

  // Listeners
  final List<Function(Transaction)> _txListeners = [];
  final List<Function(bool)> _connListeners = [];

  void onTransaction(Function(Transaction) cb) => _txListeners.add(cb);
  void onConnectionChange(Function(bool) cb) => _connListeners.add(cb);

  Future<void> connect() async {
    final token = localDb.getToken();
    final user  = localDb.getUser();
    if (token == null || user == null) return;

    // Close any existing connection first
    await _sub?.cancel();
    _sub = null;
    await _channel?.sink.close();
    _channel = null;

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('$_wsBase?token=$token&businessId=${user.businessId}'),
      );

      _sub = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _connected = true;
      _retryCount = 0;
      _notifyConn(true);
      _startPing();
      debugPrint('[WS] Connected');
    } catch (e) {
      debugPrint('[WS] Connect error: $e');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'transaction':
          final tx = Transaction.fromJson(data['payload']);
          localDb.saveTransaction(tx);
          for (final cb in _txListeners) cb(tx);
          debugPrint('[WS] New tx: ${tx.transactionId} ${tx.amount}');
          break;

        case 'pong':
          debugPrint('[WS] Pong received');
          break;

        case 'verify_result':
          // A verification completed on another terminal — update local cache
          final tx = Transaction.fromJson(data['payload']);
          localDb.saveTransaction(tx);
          for (final cb in _txListeners) cb(tx);
          break;

        default:
          debugPrint('[WS] Unknown message type: $type');
      }
    } catch (e) {
      debugPrint('[WS] Parse error: $e');
    }
  }

  void _onError(Object error) {
    debugPrint('[WS] Error: $error');
    _connected = false;
    _notifyConn(false);
    _scheduleReconnect();
  }

  void _onDone() {
    debugPrint('[WS] Connection closed');
    _connected = false;
    _notifyConn(false);
    _scheduleReconnect();
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_connected) {
        _channel?.sink.add(jsonEncode({'type': 'ping'}));
      }
    });
  }

  void _scheduleReconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    if (_retryCount >= _maxRetries) {
      debugPrint('[WS] Max retries reached — giving up');
      return;
    }
    final delay = Duration(seconds: (2 << _retryCount).clamp(2, 60));
    _retryCount++;
    debugPrint('[WS] Reconnecting in ${delay.inSeconds}s (attempt $_retryCount)');
    _reconnectTimer = Timer(delay, connect);
  }

  void _notifyConn(bool connected) {
    for (final cb in _connListeners) cb(connected);
  }

  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    await _sub?.cancel();
    await _channel?.sink.close();
    _connected = false;
    _retryCount = 0;
    _txListeners.clear();
    _connListeners.clear();
    debugPrint('[WS] Disconnected');
  }

  bool get isConnected => _connected;
}

final realtimeService = RealtimeService();
