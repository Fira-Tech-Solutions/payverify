import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/subscription_provider.dart';
import '../../../services/api/api_client.dart';
import '../../../theme/app_theme.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: subAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
                  e is ApiException ? e.message : 'Could not load subscription',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppTheme.foreground, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        data: (sub) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatusCard(sub: sub),
            const SizedBox(height: 16),
            _UsageStats(sub: sub),
            const SizedBox(height: 16),
            if (sub.isExpired || sub.isGrace)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.push('/subscription/plans'),
                  icon: const Icon(Icons.payment),
                  label: const Text('Renew Subscription'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            if (sub.isTrial)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.push('/subscription/plans'),
                  icon: const Icon(Icons.upgrade),
                  label: const Text('Upgrade Now'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            if (sub.isActive)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/subscription/plans'),
                  icon: const Icon(Icons.upgrade),
                  label: const Text('Upgrade Plan'),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.receipt_long,
                  color: AppTheme.textSecondary),
              title: const Text('Payment History'),
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.textMuted),
              onTap: () =>
                  context.push('/subscription/history'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final dynamic sub;
  const _StatusCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    if (sub.isTrial) {
      badgeColor = AppTheme.warning;
      badgeText = 'Trial';
      badgeIcon = Icons.timer;
    } else if (sub.isActive) {
      badgeColor = AppTheme.accent;
      badgeText = 'Active';
      badgeIcon = Icons.check_circle;
    } else if (sub.isGrace) {
      badgeColor = const Color(0xFFE65100);
      badgeText = 'Grace Period';
      badgeIcon = Icons.warning;
    } else {
      badgeColor = AppTheme.danger;
      badgeText = 'Expired';
      badgeIcon = Icons.block;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(badgeIcon, size: 48, color: badgeColor),
          const SizedBox(height: 12),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${sub.tier} Plan',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          if (sub.daysRemaining != null) ...[
            const SizedBox(height: 8),
            Text(
              '${sub.daysRemaining} days remaining',
              style: TextStyle(
                fontSize: 13,
                color: badgeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UsageStats extends StatelessWidget {
  final dynamic sub;
  const _UsageStats({required this.sub});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatTile(
          label: 'Verifications',
          value: '${sub.verificationCount}',
          icon: Icons.check_circle_outline,
        ),
        const SizedBox(width: 12),
        _StatTile(
          label: 'Workers',
          value: '${sub.workerCount}',
          icon: Icons.people_outline,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: AppTheme.textSecondary),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
