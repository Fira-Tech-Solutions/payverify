import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/providers.dart';
import '../../../providers/subscription_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../services/realtime/realtime_service.dart';
import '../../../services/sync/offline_sync_manager.dart';
import '../../../services/api/api_client.dart';
import '../../../utils/app_messages.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.accent,
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(user.phone,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 13)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          user.role,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _SectionHeader('Business'),
          if (user.isOwner)
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.store, color: AppTheme.accent, size: 20),
              ),
              title: Text(user.businessName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: const Text('Tap to edit business name',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              trailing: const Icon(Icons.edit_outlined,
                  color: AppTheme.textMuted, size: 18),
              onTap: () => _editBusinessName(context, ref, user.businessName),
            )
          else
            _Tile(
              icon: Icons.store,
              title: user.businessName,
              subtitle: 'Business name',
            ),
          _Tile(
            icon: Icons.tag,
            title: user.businessId,
            subtitle: 'Business ID',
            monospace: true,
          ),
          _SectionHeader('Subscription'),
          _SubscriptionTile(),
          _SectionHeader('Connection'),
          _ConnectionTile(),
          _OfflineQueueTile(),
          _SectionHeader('Supported payment methods'),
          _Tile(
              imageAsset: 'assets/bank_icons/tellebirr.jpg',
              title: 'TeleBirr',
              subtitle: 'Ethio Telecom wallet'),
          _Tile(
              imageAsset: 'assets/bank_icons/cbe.png',
              title: 'CBE',
              subtitle: 'Commercial Bank of Ethiopia (SMS: 841)'),
          _Tile(
              imageAsset: 'assets/bank_icons/awash-bank-logo.png',
              title: 'Awash Bank',
              subtitle: 'Awash International Bank'),
          _Tile(
              imageAsset: 'assets/bank_icons/Dashen_Bank.png',
              title: 'Dashen Bank',
              subtitle: 'Dashen Bank S.C.'),
          _Tile(
              icon: Icons.account_balance,
              title: 'Bank of Abyssinia',
              subtitle: 'BOA'),
          _Tile(
              imageAsset: 'assets/bank_icons/Amole-Logo.png',
              title: 'Amole',
              subtitle: 'Dashen digital wallet'),
          _Tile(
              imageAsset: 'assets/bank_icons/hello-cash.jpeg',
              title: 'HelloCash',
              subtitle: 'Kifiya Financial Technology'),
          _SectionHeader('SMS auto-capture (Android only)'),
          _SmsStatusTile(),
          _SectionHeader('Data'),
          ListTile(
            leading:
                const Icon(Icons.sync, color: AppTheme.textSecondary),
            title: const Text('Sync transactions'),
            subtitle: const Text('Pull latest from server'),
            onTap: () =>
                ref.read(transactionsProvider.notifier).sync(),
          ),
          _SectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.danger),
            title: const Text('Sign out',
                style: TextStyle(color: AppTheme.danger)),
            onTap: () => _confirmLogout(context, ref),
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text('PayVerify v1.0.0',
                style:
                    TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _editBusinessName(BuildContext context, WidgetRef ref, String current) async {
    final ctrl = TextEditingController(text: current);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit business name',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Business name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty && ctrl.text.trim() != current) {
      try {
        await api.updateBusinessName(ctrl.text.trim());
        ref.invalidate(authProvider);
        if (context.mounted) {
          AppMessages.success(context, 'Business name updated');
        }
      } catch (e) {
        if (context.mounted) {
          AppMessages.error(context, 'Failed to update: $e');
        }
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (ok == true) ref.read(authProvider.notifier).logout();
  }
}

class _SubscriptionTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(subscriptionProvider);

    return subAsync.when(
      loading: () => const ListTile(
        leading: Icon(Icons.card_membership,
            color: AppTheme.textSecondary, size: 22),
        title: Text('Subscription'),
        subtitle: Text('Loading...'),
      ),
      error: (_, __) => ListTile(
        leading: const Icon(Icons.card_membership,
            color: AppTheme.textSecondary, size: 22),
        title: const Text('Subscription'),
        subtitle: const Text('Tap to manage'),
        onTap: () => context.push('/subscription'),
      ),
      data: (sub) {
        Color statusColor;
        String statusText;

        if (sub.isTrial) {
          statusColor = AppTheme.warning;
          statusText =
              'Trial \u2022 ${sub.daysRemaining ?? '?'} days left';
        } else if (sub.isActive) {
          statusColor = AppTheme.accent;
          statusText = 'Active \u2022 ${sub.tier}';
        } else if (sub.isGrace) {
          statusColor = const Color(0xFFE65100);
          statusText =
              'Grace period \u2022 ${sub.graceDaysRemaining ?? '?'} days';
        } else {
          statusColor = AppTheme.danger;
          statusText = 'Expired';
        }

        return ListTile(
          leading: const Icon(Icons.card_membership,
              color: AppTheme.textSecondary, size: 22),
          title: const Text('Subscription'),
          subtitle: Text(statusText,
              style: TextStyle(
                  color: statusColor, fontWeight: FontWeight.w600)),
          trailing:
              const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          onTap: () => context.push('/subscription'),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
              letterSpacing: 0.8),
        ),
      );
}

class _Tile extends StatelessWidget {
  final IconData? icon;
  final String? imageAsset;
  final String title;
  final String subtitle;
  final bool monospace;
  const _Tile({
    this.icon,
    this.imageAsset,
    required this.title,
    required this.subtitle,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: imageAsset != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  imageAsset!,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                ),
              )
            : Icon(icon, color: AppTheme.textSecondary, size: 22),
        title: Text(
          title,
          style: TextStyle(
              fontSize: 14,
              fontFamily: monospace ? 'monospace' : null,
              fontWeight: FontWeight.w500),
        ),
        subtitle: Text(subtitle,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary)),
      );
}

class _ConnectionTile extends StatefulWidget {
  @override
  State<_ConnectionTile> createState() => _ConnectionTileState();
}

class _ConnectionTileState extends State<_ConnectionTile> {
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _connected = realtimeService.isConnected;
    realtimeService.onConnectionChange((c) {
      if (mounted) setState(() => _connected = c);
    });
  }

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(
          _connected ? Icons.wifi : Icons.wifi_off,
          color: _connected ? AppTheme.accent : AppTheme.warning,
          size: 22,
        ),
        title: Text(_connected ? 'Connected' : 'Offline'),
        subtitle: Text(_connected
            ? 'Real-time updates active'
            : 'Verifications will sync when back online'),
        trailing: Icon(
          Icons.circle,
          color: _connected ? AppTheme.accent : AppTheme.warning,
          size: 10,
        ),
      );
}

class _OfflineQueueTile extends StatefulWidget {
  @override
  State<_OfflineQueueTile> createState() => _OfflineQueueTileState();
}

class _OfflineQueueTileState extends State<_OfflineQueueTile> {
  @override
  Widget build(BuildContext context) {
    final queued = offlineSync.queueLength;
    if (queued == 0) return const SizedBox();

    return ListTile(
      leading: const Icon(Icons.pending_actions,
          color: AppTheme.warning, size: 22),
      title: Text(
          '$queued verification${queued > 1 ? 's' : ''} pending sync'),
      subtitle:
          const Text('Will be verified automatically when online'),
      trailing: TextButton(
        onPressed: () => offlineSync.syncNow(),
        child: const Text('Sync now'),
      ),
    );
  }
}

class _SmsStatusTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const ListTile(
      leading: Icon(Icons.sms, color: AppTheme.textSecondary, size: 22),
      title: Text('SMS auto-capture'),
      subtitle: Text(
        'On Android: bank SMS (CBE, TeleBirr, Awash) are '
        'automatically captured and added to the verification pool. '
        'iOS does not support background SMS reading.',
      ),
      isThreeLine: true,
    );
  }
}
