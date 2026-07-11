import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api/api_client.dart';
import '../../../theme/app_theme.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String tier;
  final int periodMonths;

  const PaymentScreen({
    super.key,
    required this.tier,
    required this.periodMonths,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  bool _loading = false;
  String? _error;

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

  String get _periodLabel => widget.periodMonths == 12
      ? '12 months (yearly)'
      : '${widget.periodMonths} month';

  double get _amount {
    const prices = {
      'STARTER': {'monthly': 199.0, 'yearly': 1990.0},
      'BUSINESS': {'monthly': 499.0, 'yearly': 4990.0},
      'ENTERPRISE': {'monthly': 1200.0, 'yearly': 12000.0},
    };
    final plan = prices[widget.tier];
    if (plan == null) return 0;
    return widget.periodMonths == 12
        ? plan['yearly']!
        : plan['monthly']! * widget.periodMonths;
  }

  Future<void> _createOrder() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await api.createTelebirrOrder(
          widget.tier, widget.periodMonths);
      if (!mounted) return;

      final toPayUrl = result['toPayUrl'] as String?;
      final outTradeNo = result['outTradeNo'] as String?;

      if (toPayUrl == null || outTradeNo == null) {
        throw Exception('Invalid response from server');
      }

      context.push('/subscription/telebirr', extra: {
        'toPayUrl': toPayUrl,
        'outTradeNo': outTradeNo,
        'tier': widget.tier,
        'periodMonths': widget.periodMonths,
        'amount': _amount,
      });
    } catch (e) {
      if (mounted) {
        final msg = e is ApiException ? e.message : 'Failed to create order. Please try again.';
        setState(() => _error = msg);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Order Summary',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                _SummaryRow(
                    label: 'Plan', value: '$_tierName Plan'),
                _SummaryRow(
                    label: 'Period', value: _periodLabel),
                const Divider(height: 24),
                _SummaryRow(
                    label: 'Amount',
                    value: 'ETB ${_amount.toStringAsFixed(2)}',
                    isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.accentLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.phone_android,
                    color: AppTheme.accent, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Pay with TeleBirr',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accent)),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.dangerLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppTheme.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.danger)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _createOrder,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF0A1A0A)))
                  : const Icon(Icons.payment),
              label: Text(_loading
                  ? 'Creating order...'
                  : 'Pay ETB ${_amount.toStringAsFixed(2)}'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor:
                    AppTheme.accent.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 14, color: AppTheme.textMuted),
              SizedBox(width: 4),
              Text('Secure payment via Ethio Telecom',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow(
      {required this.label,
      required this.value,
      this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textSecondary)),
          Text(value,
              style: TextStyle(
                fontSize: isBold ? 18 : 14,
                fontWeight:
                    isBold ? FontWeight.w800 : FontWeight.w600,
                color: AppTheme.textPrimary,
              )),
        ],
      ),
    );
  }
}
