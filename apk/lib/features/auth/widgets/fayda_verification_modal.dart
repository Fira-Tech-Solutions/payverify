import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class FaydaVerificationResult {
  final String userId;
  final String name;
  final String phone;

  FaydaVerificationResult({
    required this.userId,
    required this.name,
    required this.phone,
  });
}

class FaydaVerificationModal extends StatefulWidget {
  final String bizName;

  const FaydaVerificationModal({super.key, required this.bizName});

  @override
  State<FaydaVerificationModal> createState() => _FaydaVerificationModalState();
}

class _FaydaVerificationModalState extends State<FaydaVerificationModal> {
  InAppWebViewController? _controller;
  bool _isLoading = true;
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080C0A),
        foregroundColor: const Color(0xFFF2EDE4),
        title: const Text('Fayda Identity Verification',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri(
                'http://192.168.100.131:3000/v1/auth/fayda-login-init?bizName=${Uri.encodeComponent(widget.bizName)}',
              ),
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              useShouldOverrideUrlLoading: true,
            ),
            onWebViewCreated: (controller) {
              _controller = controller;
            },
            onLoadStart: (controller, url) {
              debugPrint('[Fayda WebView] Started: $url');
            },
            onLoadStop: (controller, url) {
              debugPrint('[Fayda WebView] Finished: $url');
              if (mounted) setState(() => _isLoading = false);
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final url = navigationAction.request.url?.toString() ?? '';
              debugPrint('[Fayda WebView] Navigation: $url');

              if (url.contains('/v1/auth/fayda-success') && !_handled) {
                _handled = true;
                final uri = Uri.parse(url);
                final userId = uri.queryParameters['userId'];
                final name = uri.queryParameters['name'];
                final phone = uri.queryParameters['phone'];
                if (userId != null && name != null && phone != null) {
                  Future.microtask(() {
                    if (!mounted) return;
                    Navigator.pop(
                      context,
                      FaydaVerificationResult(userId: userId, name: name, phone: phone),
                    );
                  });
                }
                return NavigationActionPolicy.CANCEL;
              }
              return NavigationActionPolicy.ALLOW;
            },
            onReceivedError: (controller, request, error) {
              debugPrint('[Fayda WebView] Error: $error');
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF276B47)),
            ),
        ],
      ),
    );
  }
}
