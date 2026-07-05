import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart';
import '../../../models/user.dart';
import '../../../theme/app_theme.dart';
import '../../../services/local_db/local_db.dart';
import '../../../utils/app_messages.dart';
import 'settings_pin_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).valueOrNull;
    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile card ──────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primary,
                    child: Text(
                      user.name.isNotEmpty
                          ? user.name.substring(0, 1).toUpperCase()
                          : 'U',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
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
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary)),
                        const SizedBox(height: 2),
                        Text(user.phone,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary)),
                        const SizedBox(height: 4),
                        Row(children: [
                          _RoleBadge(user.role),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              user.businessName,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── PIN & Security ──────────────────────────────────────
          _SectionHeader('Security'),
          Card(
            child: ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A1E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lock_outline,
                    color: AppTheme.forest, size: 20),
              ),
              title: const Text('PIN & Security',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              subtitle: const Text('Change PIN, fingerprint settings',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
              trailing: const Icon(Icons.chevron_right,
                  color: AppTheme.textMuted),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsPinScreen())),
            ),
          ),
          const SizedBox(height: 20),

          // ── Payment methods section ───────────────────────────────
          _SectionHeader('Payment methods'),
          Card(
            child: Column(
              children: [
                _ToggleTile(
                  imageAsset: 'assets/bank_icons/tellebirr.jpg',
                  label: 'TeleBirr',
                  subtitle: 'Ethio Telecom wallet',
                  prefKey: 'method_telebirr',
                  defaultVal: true,
                ),
                _Divider(),
                _ToggleTile(
                  imageAsset: 'assets/bank_icons/cbe.png',
                  label: 'CBE',
                  subtitle: 'Commercial Bank of Ethiopia',
                  prefKey: 'method_cbe',
                  defaultVal: true,
                ),
                _Divider(),
                _ToggleTile(
                  imageAsset: 'assets/bank_icons/awash-bank-logo.png',
                  label: 'Awash Bank',
                  subtitle: 'Awash International Bank',
                  prefKey: 'method_awash',
                  defaultVal: true,
                ),
                _Divider(),
                _ToggleTile(
                  imageAsset: 'assets/bank_icons/Dashen_Bank.png',
                  label: 'Dashen Bank',
                  subtitle: 'Dashen Bank S.C.',
                  prefKey: 'method_dashen',
                  defaultVal: false,
                ),
                _Divider(),
                _ToggleTile(
                  imageAsset: 'assets/bank_icons/Amole-Logo.png',
                  label: 'Amole',
                  subtitle: 'Dashen digital wallet',
                  prefKey: 'method_amole',
                  defaultVal: false,
                ),
                _Divider(),
                _ToggleTile(
                  imageAsset: 'assets/bank_icons/hello-cash.jpeg',
                  label: 'HelloCash',
                  subtitle: 'HelloCash wallet',
                  prefKey: 'method_hellocash',
                  defaultVal: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Notifications ─────────────────────────────────────────
          _SectionHeader('Notifications'),
          Card(
            child: Column(
              children: [
                _ToggleTile(
                  icon: Icons.notifications_active,
                  label: 'Sound on verification',
                  subtitle: 'Beep when payment is verified',
                  prefKey: 'notif_sound',
                  defaultVal: true,
                ),
                _Divider(),
                _ToggleTile(
                  icon: Icons.vibration,
                  label: 'Vibrate',
                  subtitle: 'Vibrate on verification result',
                  prefKey: 'notif_vibrate',
                  defaultVal: true,
                ),
                _Divider(),
                _ToggleTile(
                  icon: Icons.warning_amber,
                  label: 'Alert on mismatch',
                  subtitle: 'Strong alert for failed verifications',
                  prefKey: 'notif_mismatch',
                  defaultVal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Storage ───────────────────────────────────────────────
          _SectionHeader('Storage'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storage,
                      color: AppTheme.textSecondary),
                  title: const Text('Clear old transactions',
                      style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Remove records older than 30 days',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textMuted)),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppTheme.textMuted),
                  onTap: () => _confirmClear(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── About ─────────────────────────────────────────────────
          _SectionHeader('About'),
          Card(
            child: Column(
              children: [
                _InfoTile('Version', '1.0.0'),
                _Divider(),
                _InfoTile('Backend', '192.168.100.131:3000'),
                _Divider(),
                _InfoTile('Support', '+251 911 000 000'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Logout ────────────────────────────────────────────────
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
            ),
            onPressed: () => _confirmLogout(context, ref),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear old records?'),
        content: const Text(
            'This removes transactions older than 30 days from this device only.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
              child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) {
      await localDb.clearOldTransactions();
      if (context.mounted) {
        AppMessages.success(context, 'Old records cleared');
      }
    }
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to verify payments.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}

// ── Small helper widgets ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
                letterSpacing: 0.5)),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 56, color: AppTheme.border);
}

class _ToggleTile extends StatefulWidget {
  final IconData? icon;
  final String? imageAsset;
  final String label;
  final String subtitle;
  final String prefKey;
  final bool defaultVal;

  const _ToggleTile({
    this.icon,
    this.imageAsset,
    required this.label,
    required this.subtitle,
    required this.prefKey,
    required this.defaultVal,
  }) : assert(icon != null || imageAsset != null);

  @override
  State<_ToggleTile> createState() => _ToggleTileState();
}

class _ToggleTileState extends State<_ToggleTile> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.defaultVal;
  }

  @override
  Widget build(BuildContext context) => SwitchListTile(
        secondary: widget.imageAsset != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  widget.imageAsset!,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                ),
              )
            : Icon(widget.icon, color: AppTheme.textSecondary, size: 22),
        title: Text(widget.label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(widget.subtitle,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textMuted)),
        value: _value,
        onChanged: (v) => setState(() => _value = v),
        activeColor: AppTheme.accent,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      );
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary)),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary)),
          ],
        ),
      );
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge(this.role);
  @override
  Widget build(BuildContext context) {
    final color = role == UserRole.owner
        ? AppTheme.accent
        : role == UserRole.manager
            ? Colors.blue
            : AppTheme.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(role,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}
