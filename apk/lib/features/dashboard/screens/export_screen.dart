import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/app_messages.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  String _format = 'csv';
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Data')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Format',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _FormatOption(
              title: 'CSV',
              subtitle: 'Spreadsheet-compatible format',
              icon: Icons.table_chart,
              isSelected: _format == 'csv',
              onTap: () => setState(() => _format = 'csv'),
            ),
            const SizedBox(height: 8),
            _FormatOption(
              title: 'JSON',
              subtitle: 'Raw data format',
              icon: Icons.code,
              isSelected: _format == 'json',
              onTap: () => setState(() => _format = 'json'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _exporting ? null : _export,
                icon: _exporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0A1A0A)),
                      )
                    : const Icon(Icons.download),
                label: Text(
                    _exporting ? 'Exporting...' : 'Export Transactions'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final txs =
          ref.read(transactionsProvider).valueOrNull ?? [];
      String content;

      if (_format == 'csv') {
        final header =
            'Date,Reference,Amount,Sender,Phone,Method,Status';
        final rows = txs
            .map((tx) =>
                '${tx.timestamp.toIso8601String()},${tx.transactionId},${tx.amount},${tx.senderName},${tx.senderPhone},${tx.paymentMethod},${tx.status}')
            .join('\n');
        content = '$header\n$rows';
      } else {
        content =
            jsonEncode(txs.map((tx) => tx.toJson()).toList());
      }

      await Clipboard.setData(ClipboardData(text: content));
      if (mounted) {
        AppMessages.success(context, 'Data copied to clipboard');
      }
    } catch (e) {
      if (mounted) {
        AppMessages.error(context, e);
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

class _FormatOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.accent : AppTheme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected
                    ? AppTheme.accent
                    : AppTheme.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.accent
                          : AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppTheme.accent),
          ],
        ),
      ),
    );
  }
}
