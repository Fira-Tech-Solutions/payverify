import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart';
import '../../../models/transaction.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/app_utils.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final txsAsync = ref.watch(transactionsProvider);

    if (user == null || !user.isManager) {
      return const Scaffold(
        body: Center(child: Text('Access restricted to owners')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.white),
            onPressed: () =>
                ref.read(transactionsProvider.notifier).sync(),
          ),
        ],
      ),
      body: txsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (txs) =>
            _AnalyticsBody(txs: txs, businessId: user.businessId),
      ),
    );
  }
}

class _AnalyticsBody extends StatefulWidget {
  final List<Transaction> txs;
  final String businessId;
  const _AnalyticsBody({required this.txs, required this.businessId});

  @override
  State<_AnalyticsBody> createState() => _AnalyticsBodyState();
}

class _AnalyticsBodyState extends State<_AnalyticsBody> {
  String _period = 'today';

  List<Transaction> get _filtered {
    final now = DateTime.now();
    return widget.txs.where((t) {
      switch (_period) {
        case 'today':
          return t.timestamp.year == now.year &&
              t.timestamp.month == now.month &&
              t.timestamp.day == now.day;
        case 'week':
          return t.timestamp
              .isAfter(now.subtract(const Duration(days: 7)));
        case 'month':
          return t.timestamp.year == now.year &&
              t.timestamp.month == now.month;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final txs = _filtered;
    final verified =
        txs.where((t) => t.status == TxStatus.verified).toList();
    final mismatch =
        txs.where((t) => t.status == TxStatus.mismatch).toList();
    final total = verified.fold(0.0, (s, t) => s + t.amount);

    final byMethod = <String, double>{};
    for (final t in verified) {
      byMethod[t.paymentMethod] =
          (byMethod[t.paymentMethod] ?? 0) + t.amount;
    }
    final sortedMethods = byMethod.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: ['today', 'week', 'month']
              .map((p) => Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _period = p),
                      child: Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 3),
                        padding:
                            const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _period == p
                              ? AppTheme.accent
                              : AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _period == p
                                ? AppTheme.accent
                                : AppTheme.border,
                          ),
                        ),
                        child: Text(
                          p[0].toUpperCase() + p.substring(1),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _period == p
                                  ? const Color(0xFF0A1A0A)
                                  : AppTheme.textSecondary),
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        _SummaryCard(
          label: 'Total collected',
          value: AppUtils.formatAmount(total),
          icon: Icons.account_balance_wallet,
          color: AppTheme.accent,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Verified',
                value: '${verified.length}',
                icon: Icons.check_circle,
                color: AppTheme.accent,
                small: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Mismatches',
                value: '${mismatch.length}',
                icon: Icons.cancel,
                color:
                    mismatch.isEmpty ? AppTheme.textMuted : AppTheme.danger,
                small: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Total txns',
                value: '${txs.length}',
                icon: Icons.receipt,
                color: AppTheme.textSecondary,
                small: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (sortedMethods.isNotEmpty) ...[
          const _Label('By payment method'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: sortedMethods.map((e) {
                  final pct = total > 0 ? e.value / total : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                            Text(
                                AppUtils.formatAmountShort(e.value),
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.accent)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: AppTheme.border,
                            color: AppTheme.accent,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (verified.isNotEmpty) ...[
          const _Label('By worker'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: _workerBreakdown(verified)
                    .map((row) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    AppTheme.accent.withValues(alpha: 0.15),
                                child: Text(
                                  row['name']
                                      .toString()
                                      .substring(0, 1),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.accent),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(row['name'],
                                      style: const TextStyle(
                                          fontSize: 13))),
                              Text('${row['count']} txns',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color:
                                          AppTheme.textSecondary)),
                              const SizedBox(width: 10),
                              Text(
                                  AppUtils.formatAmountShort(
                                      row['amount'] as double),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.accent)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Map<String, dynamic>> _workerBreakdown(List<Transaction> txs) {
    final map = <String, Map<String, dynamic>>{};
    for (final t in txs) {
      final name = t.workerName ?? 'Unknown';
      map[name] ??= {'name': name, 'count': 0, 'amount': 0.0};
      map[name]!['count'] = (map[name]!['count'] as int) + 1;
      map[name]!['amount'] =
          (map[name]!['amount'] as double) + t.amount;
    }
    return map.values.toList()
      ..sort(
          (a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool small;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: EdgeInsets.all(small ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: small ? 18 : 22),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      fontSize: small ? 20 : 24,
                      fontWeight: FontWeight.w800,
                      color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary));
}
