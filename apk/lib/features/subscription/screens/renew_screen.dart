import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/subscription_provider.dart';
import '../../../services/api/api_client.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/app_messages.dart';

class RenewScreen extends ConsumerStatefulWidget {
  const RenewScreen({super.key});

  @override
  ConsumerState<RenewScreen> createState() => _RenewScreenState();
}

class _RenewScreenState extends ConsumerState<RenewScreen> {
  bool _polling = false;

  @override
  Widget build(BuildContext context) {
    final subAsync = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Renew Subscription')),
      body: subAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    color: AppTheme.destructive, size: 40),
                const SizedBox(height: 12),
                Text(
                  e is ApiException ? e.message : 'Something went wrong',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppTheme.foreground, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        data: (sub) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Payment Methods',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _PaymentMethod(
                name: 'TeleBirr',
                icon: Icons.phone_android,
                details: 'Send to: 0912 34 56 78',
                color: const Color(0xFF4CAF50),
              ),
              _PaymentMethod(
                name: 'CBE',
                icon: Icons.account_balance,
                details: 'Account: 1000 2345 6789',
                color: const Color(0xFF4A9EFF),
              ),
              _PaymentMethod(
                name: 'Awash Bank',
                icon: Icons.account_balance_wallet,
                details: 'Account: 9876 5432 1012',
                color: const Color(0xFFE07040),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Your Reference Code',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Use this code as payment reference',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'PV-XXXXXX-STR',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(
                                  const ClipboardData(
                                      text: 'PV-XXXXXX-STR'));
                              AppMessages.success(
                                  context, 'Reference code copied');
                            },
                            icon: const Icon(Icons.copy,
                                size: 20,
                                color: Colors.white70),
                            tooltip: 'Copy',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'How to pay',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _instructionStep(1,
                  'Open your bank app (TeleBirr, CBE, or Awash)'),
              _instructionStep(
                  2, 'Send the exact amount for your plan'),
              _instructionStep(3,
                  'Use the reference code above as payment reference'),
              _instructionStep(4,
                  'Tap "I\'ve Paid" below and wait for activation'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _polling ? null : _verifyPayment,
                  icon: _polling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF0A1A0A)),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                      _polling ? 'Checking...' : 'I\'ve Paid'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    disabledBackgroundColor:
                        AppTheme.accent.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _instructionStep(int step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: AppTheme.accent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A1A0A),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPayment() async {
    setState(() => _polling = true);
    try {
      for (int i = 0; i < 5; i++) {
        await Future.delayed(const Duration(seconds: 3));
        final status =
            await ref.read(subscriptionProvider.future);
        if (status.isActive) {
          if (mounted) {
            AppMessages.success(
                context, 'Subscription activated!');
            Navigator.pop(context);
          }
          return;
        }
      }
      if (mounted) {
        AppMessages.warning(context,
            'Payment not detected yet. Try again in a few minutes.');
      }
    } catch (e) {
      if (mounted) {
        AppMessages.error(context, e);
      }
    } finally {
      if (mounted) setState(() => _polling = false);
    }
  }
}

class _PaymentMethod extends StatelessWidget {
  final String name;
  final IconData icon;
  final String details;
  final Color color;

  const _PaymentMethod({
    required this.name,
    required this.icon,
    required this.details,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  details,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
