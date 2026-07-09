import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    final baseUrl = 'http://192.168.100.131:3000/v1';
    final initUrl = '$baseUrl/auth/fayda-login-init?bizName=${Uri.encodeComponent(widget.bizName)}';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            debugPrint('[Fayda WebView] Started: $url');
          },
          onPageFinished: (url) {
            debugPrint('[Fayda WebView] Finished: $url');
            if (mounted) setState(() => _isLoading = false);
          },
          onNavigationRequest: (request) {
            final url = request.url;
            debugPrint('[Fayda WebView] Navigation: $url');

            // Intercept the fayda-success redirect
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
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            debugPrint('[Fayda WebView] Error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(initUrl));
  }

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
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF276B47)),
            ),
        ],
      ),
    );
  }
}
