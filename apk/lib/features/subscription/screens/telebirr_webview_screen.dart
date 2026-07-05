import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../services/api/api_client.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/app_messages.dart';

class TeleBirrWebViewScreen extends StatefulWidget {
  final String toPayUrl;
  final String outTradeNo;
  final String tier;
  final int periodMonths;
  final double amount;

  const TeleBirrWebViewScreen({
    super.key,
    required this.toPayUrl,
    required this.outTradeNo,
    required this.tier,
    required this.periodMonths,
    required this.amount,
  });

  @override
  State<TeleBirrWebViewScreen> createState() => _TeleBirrWebViewScreenState();
}

class _TeleBirrWebViewScreenState extends State<TeleBirrWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _paymentDetected = false;
  Timer? _pollTimer;
  int _pollAttempts = 0;
  static const _maxPollAttempts = 15;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('[TeleBirr WebView] Page started: $url');
          },
          onPageFinished: (url) async {
            debugPrint('[TeleBirr WebView] Page finished: $url');
            if (mounted) setState(() => _isLoading = false);
            _checkUrlForPaymentStatus(url);
          },
          onNavigationRequest: (request) {
            final url = request.url;
            debugPrint('[TeleBirr WebView] Navigation: $url');

            // Intercept deep link redirect
            if (url.startsWith('payverify://')) {
              _handleDeepLink(url);
              return NavigationDecision.prevent;
            }

            // Detect payment success/failure via URL patterns
            if (url.contains('trade_status=TRADE_SUCCESS') ||
                url.contains('/paymentmall/pay/success')) {
              if (!_paymentDetected) {
                _paymentDetected = true;
                _pollTimer?.cancel();
                _onPaymentSuccess();
              }
              return NavigationDecision.prevent;
            }

            if (url.contains('trade_status=TRADE_FAIL') ||
                url.contains('trade_status=TRADE_CLOSED') ||
                url.contains('/paymentmall/pay/fail')) {
              _pollTimer?.cancel();
              _onPaymentFailed();
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..setUserAgent('PayVerify/1.0 Ethiopia TeleBirrH5')
      ..loadRequest(Uri.parse(widget.toPayUrl));

    _startOrderPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startOrderPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_paymentDetected || _pollAttempts >= _maxPollAttempts) {
        _pollTimer?.cancel();
        return;
      }
      _pollAttempts++;

      try {
        final status = await api.getOrderStatus(widget.outTradeNo);
        if (status['status'] == 'PAID' && mounted) {
          _paymentDetected = true;
          _pollTimer?.cancel();
          _onPaymentSuccess();
        }
      } catch (_) {}
    });
  }

  void _checkUrlForPaymentStatus(String url) {
    if (_paymentDetected) return;

    if (url.contains('trade_status=TRADE_SUCCESS') ||
        url.contains('/paymentmall/pay/success')) {
      _paymentDetected = true;
      _pollTimer?.cancel();
      _onPaymentSuccess();
    } else if (url.contains('trade_status=TRADE_FAIL') ||
        url.contains('trade_status=TRADE_CLOSED') ||
        url.contains('/paymentmall/pay/fail')) {
      _pollTimer?.cancel();
      _onPaymentFailed();
    }
  }

  void _handleDeepLink(String url) {
    _pollTimer?.cancel();
    final uri = Uri.parse(url);
    final status = uri.queryParameters['status'];
    if (status == 'TRADE_SUCCESS') {
      _onPaymentSuccess();
    } else {
      _onPaymentFailed();
    }
  }

  void _onPaymentSuccess() {
    if (!mounted) return;
    context.go('/subscription/success', extra: {
      'tier': widget.tier,
      'periodMonths': widget.periodMonths,
      'amount': widget.amount,
    });
  }

  void _onPaymentFailed() {
    if (!mounted) return;
    AppMessages.errorWithAction(
      context,
      'Payment was not completed. Please try again.',
      actionLabel: 'Retry',
      onAction: _retryPayment,
    );
    Navigator.pop(context);
  }

  Future<void> _retryPayment() async {
    try {
      final result = await api.createTelebirrOrder(widget.tier, widget.periodMonths);
      if (!mounted) return;
      final toPayUrl = result['toPayUrl'] as String?;
      if (toPayUrl != null) {
        _controller.loadRequest(Uri.parse(toPayUrl));
        setState(() {
          _isLoading = true;
          _paymentDetected = false;
          _pollAttempts = 0;
        });
        _startOrderPolling();
      }
    } catch (_) {}
  }

  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel payment?'),
        content: const Text('Your payment has not been completed. Are you sure you want to go back?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continue paying'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pay with TeleBirr'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) Navigator.pop(context);
            },
          ),
          bottom: _isLoading
              ? const PreferredSize(
                  preferredSize: Size.fromHeight(3),
                  child: LinearProgressIndicator(),
                )
              : null,
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
