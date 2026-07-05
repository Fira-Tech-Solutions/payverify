import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/providers.dart';
import '../../../models/transaction.dart';
import '../../../services/local_db/local_db.dart';
import '../../../theme/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    final txsAsync = ref.watch(transactionsProvider);

    if (user == null) return const SizedBox();

    final summary = localDb.getDailySummary(user.businessId);
    final totalAmount = (summary['totalAmount'] as num).toDouble();
    final verified = summary['verified'] as int;
    final mismatch = summary['mismatch'] as int;
    final total = summary['total'] as int;

    return Scaffold(
      appBar: AppBar(
        title: Text(user.businessName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () =>
                ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(transactionsProvider.notifier).sync(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Today · ${DateFormat('MMMM d').format(DateTime.now())}',
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Total collected',
                    value:
                        'ETB ${NumberFormat('#,##0').format(totalAmount)}',
                    color: AppTheme.accent,
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    label: 'Verifications',
                    value: '$total',
                    color: AppTheme.textSecondary,
                    icon: Icons.verified,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Verified',
                    value: '$verified',
                    color: AppTheme.accent,
                    icon: Icons.check_circle_outline,
                    small: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    label: 'Mismatches',
                    value: '$mismatch',
                    color: mismatch > 0
                        ? AppTheme.danger
                        : AppTheme.textMuted,
                    icon: Icons.cancel_outlined,
                    small: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent transactions',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () {},
                  child: const Text('See all',
                      style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            txsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('$e',
                  style: const TextStyle(color: AppTheme.danger)),
              data: (txs) {
                final recent = txs.take(10).toList();
                if (recent.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('No transactions today',
                          style:
                              TextStyle(color: AppTheme.textMuted)),
                    ),
                  );
                }
                return Column(
                  children: recent
                      .map((tx) => _MiniTxRow(tx: tx))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool small;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
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
              Text(
                value,
                style: TextStyle(
                    fontSize: small ? 20 : 24,
                    fontWeight: FontWeight.w800,
                    color: color),
              ),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
}

class _MiniTxRow extends StatelessWidget {
  final Transaction tx;
  const _MiniTxRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isOk = tx.status == TxStatus.verified;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            isOk ? Icons.check_circle : Icons.cancel,
            color: isOk ? AppTheme.accent : AppTheme.danger,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.senderName.isNotEmpty
                      ? tx.senderName
                      : tx.transactionId,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${tx.paymentMethod} · ${DateFormat('HH:mm').format(tx.timestamp)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          Text(
            'ETB ${NumberFormat('#,##0').format(tx.amount)}',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isOk ? AppTheme.accent : AppTheme.danger),
          ),
        ],
      ),
    );
  }
}
