import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth/pin_auth_service.dart';
import '../../../services/auth/biometric_service.dart';
import '../../../providers/providers.dart';
import '../../../theme/app_theme.dart';
import 'change_pin_screen.dart';

class SettingsPinScreen extends ConsumerStatefulWidget {
  const SettingsPinScreen({super.key});

  @override
  ConsumerState<SettingsPinScreen> createState() => _SettingsPinScreenState();
}

class _SettingsPinScreenState extends ConsumerState<SettingsPinScreen> {
  String _activeMode = 'PIN';
  bool _biometricAvailable = false;
  String _biometricLabel = 'Biometric';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final mode = await pinAuthService.getActiveMode();
    final available = await biometricService.isAvailable &&
        await biometricService.hasBiometricEnrolled;
    final label = await biometricService.biometricLabel;
    if (!mounted) return;
    setState(() {
      _activeMode = mode;
      _biometricAvailable = available;
      _biometricLabel = label;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(title: const Text('PIN & Security')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildModeSelector(),
          const SizedBox(height: 24),
          _buildPinCard(),
          if (_biometricAvailable) ...[
            const SizedBox(height: 24),
            _buildBiometricCard(),
          ],
          const SizedBox(height: 24),
          _buildDangerZone(),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    final pinActive = _activeMode == 'PIN';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Default unlock method',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _setMode('PIN'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: pinActive
                          ? const Color(0xFF2C2C2E)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pin_outlined,
                          size: 18,
                          color: pinActive
                              ? const Color(0xFF34C759)
                              : Colors.white.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'PIN',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: pinActive
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_biometricAvailable)
                Expanded(
                  child: GestureDetector(
                    onTap: () => _setMode('BIOMETRIC'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: !pinActive
                            ? const Color(0xFF2C2C2E)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fingerprint,
                            size: 18,
                            color: !pinActive
                                ? const Color(0xFF34C759)
                                : Colors.white.withValues(alpha: 0.4),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _biometricLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: !pinActive
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          pinActive
              ? 'PIN will be used to unlock the app by default.'
              : '$_biometricLabel will be used to unlock the app by default. PIN works as fallback.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildPinCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.pin_outlined,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            title: const Text(
              'PIN',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '6-digit code — always works as fallback',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ),
          Divider(
            height: 1,
            indent: 56,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          ListTile(
            leading: const Icon(Icons.lock_reset, color: AppTheme.destructive),
            title: const Text(
              'Change PIN',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.destructive,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePinScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.fingerprint, color: Color(0xFF34C759)),
        title: Text(
          _biometricLabel,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          "Uses your device's secure enclave",
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.lock_reset, color: AppTheme.destructive),
        title: const Text(
          'Reset PIN',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.destructive,
          ),
        ),
        subtitle: Text(
          'Remove PIN and biometric lock',
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        onTap: () => _confirmReset(),
      ),
    );
  }

  Future<void> _setMode(String mode) async {
    await pinAuthService.setActiveMode(mode);
    setState(() => _activeMode = mode);
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset PIN?'),
        content: const Text(
          'This will remove your PIN and disable biometric unlock. You will need to set up a new PIN.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.destructive),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await pinAuthService.clearPin();
      await ref.read(authProvider.notifier).logout();
    }
  }
}
