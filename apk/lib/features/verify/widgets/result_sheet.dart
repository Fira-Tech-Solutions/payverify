import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction.dart';
import '../../../theme/app_theme.dart';

class ResultSheet extends StatelessWidget {
  final Transaction transaction;

  const ResultSheet({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isVerified = transaction.status == TxStatus.verified;
    final isMismatch = transaction.status == TxStatus.mismatch;

    final color  = isVerified ? AppTheme.accent
                  : isMismatch ? AppTheme.danger
                  : AppTheme.warning;
    final bgColor = isVerified ? AppTheme.accentLight
                  : isMismatch ? AppTheme.dangerLight
                  : AppTheme.warningLight;
    final icon   = isVerified ? Icons.check_circle
                  : isMismatch ? Icons.cancel
                  : Icons.access_time;
    final label  = isVerified ? 'Payment Verified'
                  : isMismatch ? 'Payment Mismatch'
                  : 'Pending';

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              children: [
                // Status icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 36),
                ),
                const SizedBox(height: 16),

                // Status label
                Text(label,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: color)),
                const SizedBox(height: 4),
                Text(
                  transaction.paymentMethod,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 24),

                // Amount
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 32),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text('Amount',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textMuted)),
                      const SizedBox(height: 4),
                      Text(
                        'ETB ${NumberFormat('#,##0.00').format(transaction.amount)}',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: color),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Details
                _DetailRow(
                    label: 'From',
                    value: transaction.senderName.isNotEmpty
                        ? transaction.senderName
                        : 'Unknown'),
                _DetailRow(
                    label: 'Phone',
                    value: transaction.senderPhone.isNotEmpty
                        ? transaction.senderPhone
                        : '—'),
                _DetailRow(label: 'Ref ID', value: transaction.transactionId),
                _DetailRow(
                    label: 'Time',
                    value: DateFormat('MMM d, y · HH:mm')
                        .format(transaction.timestamp)),
                if (transaction.workerName != null)
                  _DetailRow(
                      label: 'Verified by', value: transaction.workerName!),

                const SizedBox(height: 24),

                // Mismatch warning
                if (isMismatch) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: AppTheme.danger, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This reference was not found or already used. Do not release goods.',
                            style: TextStyle(
                                fontSize: 13, color: AppTheme.danger),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Close button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isVerified ? AppTheme.accent : AppTheme.primary,
                    ),
                    child: const Text('Done'),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textMuted)),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
}
