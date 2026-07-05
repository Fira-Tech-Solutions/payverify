import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart';
import '../../../theme/app_theme.dart';
import '../../../services/api/api_client.dart';
import '../../../utils/app_utils.dart';

class TrendsScreen extends ConsumerStatefulWidget {
  const TrendsScreen({super.key});

  @override
  ConsumerState<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends ConsumerState<TrendsScreen> {
  String _period = 'month';
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await api.getDashboardStats(_period);
      if (mounted) setState(() => _data = data);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trends')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: ['today', 'week', 'month'].map((p) {
                final isSelected = _period == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(p[0].toUpperCase() + p.substring(1)),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _period = p);
                      _load();
                    },
                    selectedColor: AppTheme.accent,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF0A1A0A)
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_loading)
            const Expanded(
                child: Center(child: CircularProgressIndicator()))
          else if (_data == null)
            const Expanded(child: Center(child: Text('No data')))
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _StatCard(
                    label: 'Total Amount',
                    value: AppUtils.formatAmount(
                        (_data!['totalAmount'] ?? 0).toDouble()),
                    icon: Icons.attach_money,
                    color: AppTheme.accent,
                  ),
                  _StatCard(
                    label: 'Verified',
                    value: '${_data!['verifiedCount'] ?? 0}',
                    icon: Icons.check_circle,
                    color: AppTheme.accent,
                  ),
                  _StatCard(
                    label: 'Mismatch',
                    value: '${_data!['mismatchCount'] ?? 0}',
                    icon: Icons.cancel,
                    color: AppTheme.danger,
                  ),
                  _StatCard(
                    label: 'Success Rate',
                    value:
                        '${(_data!['successRate'] ?? 0).toStringAsFixed(1)}%',
                    icon: Icons.percent,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
