import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth/pin_auth_service.dart';
import '../../../services/auth/biometric_service.dart';
import '../../../providers/pin_provider.dart';
import '../../../providers/providers.dart';
import '../../../services/local_db/local_db.dart';
import '../../../theme/app_theme.dart';
import '../widgets/payverify_keypad.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;

  const PinLockScreen({super.key, required this.onUnlocked});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen>
    with SingleTickerProviderStateMixin {
  List<String> _entered = [];
  bool _isError = false;
  bool _isLockedOut = false;
  Duration _lockRemaining = Duration.zero;
  bool _biometricAvailable = false;
  bool _isAuthenticating = false;
  Timer? _lockTimer;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialState();
    });
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    biometricService.stopAuth();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialState() async {
    final bioAvail = await biometricService.isAvailable &&
        await biometricService.hasBiometricEnrolled;
    final lockedOut = await pinAuthService.isLockedOut;

    if (!mounted) return;

    setState(() {
      _biometricAvailable = bioAvail;
      _isLockedOut = lockedOut;
    });

    if (lockedOut) {
      _startLockTimer();
    }
  }

  Future<void> _triggerBiometric() async {
    if (!_biometricAvailable || _isAuthenticating) return;

    setState(() => _isAuthenticating = true);

    try {
      final success = await biometricService.authenticate(reason: 'Unlock PayVerify');
      if (!mounted) return;

      setState(() => _isAuthenticating = false);

      if (success) {
        _unlock();
      } else {
        HapticFeedback.vibrate();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAuthenticating = false);
      HapticFeedback.vibrate();
    }
  }

  void _unlock() {
    HapticFeedback.heavyImpact();
    widget.onUnlocked();
  }

  void _onDigit(String d) {
    if (_isLockedOut || _entered.length >= 6) return;
    setState(() {
      _entered = [..._entered, d];
      _isError = false;
    });
    if (_entered.length == 6) {
      _submitPin();
    }
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() {
      _entered = _entered.sublist(0, _entered.length - 1);
      _isError = false;
    });
  }

  Future<void> _submitPin() async {
    final pin = _entered.join();
    final result = await pinAuthService.verifyPin(pin);

    if (!mounted) return;

    if (result.isSuccess) {
      _unlock();
    } else if (result.isLockedOut) {
      setState(() {
        _isLockedOut = true;
        _lockRemaining = result.lockDuration;
      });
      _startLockTimer();
    } else {
      _shakeController.forward(from: 0);
      HapticFeedback.vibrate();
      setState(() => _isError = true);
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) setState(() => _entered = []);
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) setState(() => _isError = false);
    }
  }

  void _startLockTimer() {
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final remaining = await pinAuthService.lockoutRemaining;
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (remaining == null) {
        timer.cancel();
        setState(() {
          _isLockedOut = false;
          _entered = [];
        });
      } else {
        setState(() => _lockRemaining = remaining);
      }
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.obsidianLight,
        title: const Text(
          'Sign in again',
          style: TextStyle(
            color: AppTheme.foreground,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'You will need to sign in with your password again.',
          style: TextStyle(color: AppTheme.mutedForeground, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.mutedForeground)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await pinAuthService.clearPin();
              ref.read(authProvider.notifier).logout();
              if (mounted) context.go('/login');
            },
            child: const Text('Sign in', style: TextStyle(color: AppTheme.gold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = localDb.getUser();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
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
                  const SizedBox(height: 16),
                  Text(
                    user?.businessName ?? 'PayVerify',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.name ?? '',
                    style: const TextStyle(
                      color: AppTheme.mutedForeground,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (!_isLockedOut) ...[
                    _buildPinDots(),
                    const SizedBox(height: 16),
                    AnimatedOpacity(
                      opacity: _isError ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Text(
                        'Incorrect PIN',
                        style: TextStyle(color: AppTheme.destructive, fontSize: 13),
                      ),
                    ),
                    if (_biometricAvailable) ...[
                      const SizedBox(height: 12),
                      AnimatedOpacity(
                        opacity: _isAuthenticating ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const Text(
                          'Authenticating...',
                          style: TextStyle(color: AppTheme.gold, fontSize: 13),
                        ),
                      ),
                    ],
                  ] else ...[
                    const Icon(Icons.lock_outline, size: 48, color: AppTheme.gold),
                    const SizedBox(height: 16),
                    const Text(
                      'Too many attempts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDuration(_lockRemaining),
                      style: const TextStyle(
                        color: AppTheme.gold,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!_isLockedOut) ...[
              TextButton(
                onPressed: _showForgotPinDialog,
                child: const Text(
                  'Forgot PIN?',
                  style: TextStyle(color: AppTheme.mutedForeground, fontSize: 13),
                ),
              ),
              PayVerifyKeypad(
                onDigit: _onDigit,
                onBackspace: _onBackspace,
                onFingerprintTap: _biometricAvailable ? _triggerBiometric : null,
                showFingerprint: _biometricAvailable,
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    return AnimatedBuilder(
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
          if (i < _entered.length) {
            bgColor = _isError ? AppTheme.destructive : AppTheme.forest;
          } else {
            bgColor = const Color(0xFF1A1A1A);
          }
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
          );
        }),
      ),
    );
  }
}
