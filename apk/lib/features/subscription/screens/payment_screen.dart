import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String? _rawRequest;
  String? _outTradeNo;

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

      final rawRequest = result['rawRequest'] as String?;
      final outTradeNo = result['outTradeNo'] as String?;

      if (rawRequest == null || outTradeNo == null) {
        throw Exception('Invalid response from server');
      }

      setState(() {
        _rawRequest = rawRequest;
        _outTradeNo = outTradeNo;
      });

      await _launchTeleBirr(rawRequest);
    } catch (e) {
      if (mounted) {
        final msg = e is ApiException ? e.message : 'Failed to create order. Please try again.';
        setState(() => _error = msg);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _launchTeleBirr(String rawRequest) async {
    final telebirrUrl = Uri.parse(
        'telebirr://pay?rawRequest=${Uri.encodeComponent(rawRequest)}');

    if (await canLaunchUrl(telebirrUrl)) {
      await launchUrl(telebirrUrl,
          mode: LaunchMode.externalApplication);
    } else {
      debugPrint(
          '[Payment] TeleBirr app not installed, showing manual flow');
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
                  child: Text('Pay with TeleBirr SuperApp',
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
                            fontSize: 13,
                            color: AppTheme.danger)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (_rawRequest == null)
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
          if (_rawRequest != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 18, color: AppTheme.accent),
                      SizedBox(width: 8),
                      Text('Complete payment in TeleBirr',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accent)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Open your TeleBirr app and complete the payment. The order will be confirmed automatically.',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  if (_outTradeNo != null)
                    Text('Order: $_outTradeNo',
                        style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: AppTheme.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _rawRequest != null
                    ? () => _launchTeleBirr(_rawRequest!)
                    : null,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open TeleBirr'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/subscription'),
                icon: const Icon(Icons.check),
                label: const Text('Check payment status'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
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
                  fontSize: 14,
                  color: AppTheme.textSecondary)),
          Text(value,
              style: TextStyle(
                fontSize: isBold ? 18 : 14,
                fontWeight:
                    isBold ? FontWeight.w800 : FontWeight.w600,
                color: isBold
                    ? AppTheme.textPrimary
                    : AppTheme.textPrimary,
              )),
        ],
      ),
    );
  }
}
