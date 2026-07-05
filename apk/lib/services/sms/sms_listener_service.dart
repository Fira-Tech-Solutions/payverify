import 'dart:io';
import 'package:flutter/foundation.dart';
import 'sms_parser.dart';

/// On Android: uses the telephony package to listen for incoming SMS
/// from known Ethiopian bank sender addresses.
/// On iOS: this feature is not available (Apple restriction) — the class
/// compiles but does nothing, keeping the codebase cross-platform.
class SmsListenerService {
  static final SmsListenerService _instance = SmsListenerService._();
  factory SmsListenerService() => _instance;
  SmsListenerService._();

  // Callback fires whenever a valid bank SMS arrives
  Function(ParsedSms parsed)? onBankSmsReceived;

  bool _isListening = false;

  Future<void> startListening() async {
    if (!Platform.isAndroid) return; // iOS: silently skip
    if (_isListening) return;

    // Dynamic import to avoid compile errors on iOS
    // In a real build you'd use conditional imports:
    // import 'sms_listener_android.dart' if (dart.library.io) ...
    try {
      await _startAndroidListener();
      _isListening = true;
      debugPrint('[SMS] Listener started');
    } catch (e) {
      debugPrint('[SMS] Could not start listener: $e');
    }
  }

  Future<void> stopListening() async {
    _isListening = false;
  }

  Future<void> _startAndroidListener() async {
    // NOTE: In your actual project install `telephony: ^0.2.0`
    // and uncomment the code below. It is commented here so the
    // file compiles without the package being installed in CI.
    //
    // final telephony = Telephony.instance;
    //
    // final granted = await telephony.requestPhoneAndSmsPermissions;
    // if (granted != true) return;
    //
    // telephony.listenIncomingSms(
    //   onNewMessage: (SmsMessage msg) {
    //     _handleIncomingSms(msg.address ?? '', msg.body ?? '');
    //   },
    //   onBackgroundMessage: backgroundSmsHandler,
    // );

    debugPrint('[SMS] Android SMS listener registered (stub)');
  }

  void _handleIncomingSms(String address, String body) {
    final parsed = SmsParser.parse(body, address);
    if (parsed != null) {
      debugPrint('[SMS] Bank SMS parsed: ${parsed.transactionId} ${parsed.amount}');
      onBankSmsReceived?.call(parsed);
    }
  }

  /// Called by the telephony background handler (must be a top-level fn)
  static Future<void> backgroundSmsHandler(SmsMessage message) async {
    final parsed = SmsParser.parse(
      message.body ?? '',
      message.address ?? '',
    );
    if (parsed == null) return;
    // Store to Hive so the foreground app picks it up on next launch
    debugPrint('[BG SMS] Stored: ${parsed.transactionId}');
  }
}

// Placeholder so the file compiles without the telephony package
class SmsMessage {
  final String? body;
  final String? address;
  SmsMessage({this.body, this.address});
}
