import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';

class SubscriptionSuccessScreen extends StatefulWidget {
  final String tier;
  final int periodMonths;
  final double amount;

  const SubscriptionSuccessScreen({
    super.key,
    required this.tier,
    required this.periodMonths,
    required this.amount,
  });

  @override
  State<SubscriptionSuccessScreen> createState() =>
      _SubscriptionSuccessScreenState();
}

class _SubscriptionSuccessScreenState
    extends State<SubscriptionSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late ConfettiController _confettiController;

  String get _tierName {
    switch (widget.tier) {
      case 'STARTER':
        return 'Starter';
      case 'BUSINESS':
        return 'Business';
      case 'ENTERPRISE':
        return 'Enterprise';
      default:
        return widget.tier;
    }
  }

  DateTime get _expiryDate {
    final now = DateTime.now();
    if (widget.periodMonths == 12) {
      return DateTime(now.year + 1, now.month, now.day);
    }
    return DateTime(
        now.year, now.month + widget.periodMonths, now.day);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));

    _controller.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _confettiController.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality:
                  BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppTheme.accent,
                Colors.amber,
                Colors.blue,
                Colors.purple,
                Colors.white,
              ],
              createParticlePath: _drawConfettiPath,
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 56,
                        color: Color(0xFF0A1A0A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Subscription Activated!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$_tierName Plan',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Valid until ${_formatDate(_expiryDate)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.go('/app');
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text(
                          'Start Verifying Payments'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Path _drawConfettiPath(Size size) {
    final path = Path();
    path.addRect(Rect.fromLTWH(
        0, 0, size.width * 0.15, size.height * 0.15));
    return path;
  }
}
