import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth/pin_auth_service.dart';
import '../../../services/auth/biometric_service.dart';
import '../../../providers/pin_provider.dart';
import '../../../theme/app_theme.dart';
import '../widgets/payverify_keypad.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen>
    with SingleTickerProviderStateMixin {
  List<String> _pin = [];
  List<String> _confirmPin = [];
  bool _isConfirming = false;
  bool _mismatch = false;
  bool _saving = false;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 10, end: -6), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 20),
    ]).animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  List<String> get _currentPin => _isConfirming ? _confirmPin : _pin;

  void _onDigit(String digit) {
    if (_currentPin.length >= 6) return;
    setState(() {
      if (_isConfirming) {
        _confirmPin = [..._confirmPin, digit];
      } else {
        _pin = [..._pin, digit];
      }
      _mismatch = false;
    });
    if (_currentPin.length == 6) {
      _autoSubmit();
    }
  }

  void _onBackspace() {
    if (_currentPin.isEmpty) return;
    setState(() {
      if (_isConfirming) {
        _confirmPin = _confirmPin.sublist(0, _confirmPin.length - 1);
      } else {
        _pin = _pin.sublist(0, _pin.length - 1);
      }
      _mismatch = false;
    });
  }

  Future<void> _autoSubmit() async {
    if (!_isConfirming) {
      setState(() => _isConfirming = true);
      return;
    }

    final pinStr = _pin.join();
    final confirmStr = _confirmPin.join();

    if (pinStr != confirmStr) {
      setState(() => _mismatch = true);
      HapticFeedback.vibrate();
      _shakeController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _confirmPin = [];
        _mismatch = false;
      });
      return;
    }

    setState(() => _saving = true);
    await pinAuthService.setupPin(pinStr);
    if (!mounted) return;
    setState(() => _saving = false);

    if (!mounted) return;
    final available = await biometricService.isAvailable &&
        await biometricService.hasBiometricEnrolled;
    if (!mounted) return;

    if (available) {
      _showBiometricPrompt();
    } else {
      await pinAuthService.setActiveMode('PIN');
      _finish();
    }
  }

  void _showBiometricPrompt() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => _BiometricSheet(
        onEnable: () async {
          Navigator.pop(context);
          await pinAuthService.setBiometricEnabled(true);
          await pinAuthService.setActiveMode('BIOMETRIC');
          _finish();
        },
        onSkip: () {
          Navigator.pop(context);
          pinAuthService.setActiveMode('PIN');
          _finish();
        },
      ),
    );
  }

  void _finish() {
    ref.read(appLockProvider.notifier).state = false;
    context.go('/app');
  }

  @override
  Widget build(BuildContext context) {
    final dots = _isConfirming ? _confirmPin : _pin;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.gold, width: 2),
              ),
              padding: const EdgeInsets.all(4),
              child: ClipOval(
                child: Image.asset(
                  'assets/payverify_icons/payverify_icon_512x512.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isConfirming ? 'Confirm your PIN' : 'Create a PIN',
              style: const TextStyle(
                color: AppTheme.foreground,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isConfirming
                  ? 'Re-enter your 6-digit PIN to confirm'
                  : 'Choose a 6-digit PIN to secure your account',
              style: const TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnimation.value, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  Color bgColor;
                  if (i < dots.length) {
                    bgColor = _mismatch ? AppTheme.destructive : AppTheme.forest;
                  } else {
                    bgColor = const Color(0xFF1A1A1A);
                  }
                  return Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bgColor,
                      border: Border.all(
                        color: i < dots.length
                            ? (_mismatch
                                ? AppTheme.destructive
                                : AppTheme.forest)
                            : const Color(0xFF2A2A2A),
                      ),
                    ),
                  );
                }),
              ),
            ),
            AnimatedOpacity(
              opacity: _mismatch ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const Text(
                'PINs do not match. Try again.',
                style: TextStyle(
                  color: AppTheme.destructive,
                  fontSize: 13,
                ),
              ),
            ),
            const Spacer(),
            IgnorePointer(
              ignoring: _saving,
              child: PayVerifyKeypad(
                onDigit: _onDigit,
                onBackspace: _onBackspace,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
          ],
        ),
      ),
    );
  }
}

class _BiometricSheet extends StatelessWidget {
  final VoidCallback onEnable;
  final VoidCallback onSkip;

  const _BiometricSheet({
    required this.onEnable,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.obsidianLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.fingerprint,
            size: 64,
            color: AppTheme.gold,
          ),
          const SizedBox(height: 20),
          const Text(
            'Enable fingerprint unlock?',
            style: TextStyle(
              color: AppTheme.foreground,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use your fingerprint for faster sign-in',
            style: TextStyle(
              color: AppTheme.mutedForeground,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onEnable,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.forest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Enable'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: onSkip,
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: AppTheme.mutedForeground,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
