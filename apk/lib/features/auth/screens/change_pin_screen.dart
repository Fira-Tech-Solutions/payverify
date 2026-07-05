import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/auth/pin_auth_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/app_messages.dart';
import '../widgets/payverify_keypad.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen>
    with SingleTickerProviderStateMixin {
  String _currentPin = '';
  String _newPin = '';
  String _confirmPin = '';
  int _step = 1;
  String? _error;
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

  String get _activePin {
    switch (_step) {
      case 1:
        return _currentPin;
      case 2:
        return _newPin;
      case 3:
        return _confirmPin;
      default:
        return '';
    }
  }

  void _onDigit(String digit) {
    if (_activePin.length >= 6) return;
    setState(() {
      _error = null;
      switch (_step) {
        case 1:
          _currentPin += digit;
          break;
        case 2:
          _newPin += digit;
          break;
        case 3:
          _confirmPin += digit;
          break;
      }
    });
    if (_activePin.length == 6) {
      _autoAdvance();
    }
  }

  void _onBackspace() {
    if (_activePin.isEmpty) return;
    setState(() {
      _error = null;
      switch (_step) {
        case 1:
          _currentPin = _currentPin.substring(0, _currentPin.length - 1);
          break;
        case 2:
          _newPin = _newPin.substring(0, _newPin.length - 1);
          break;
        case 3:
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
          break;
      }
    });
  }

  Future<void> _autoAdvance() async {
    switch (_step) {
      case 1:
        setState(() => _saving = true);
        final result = await pinAuthService.verifyPin(_currentPin);
        setState(() => _saving = false);
        if (!mounted) return;

        if (result.isSuccess) {
          setState(() {
            _step = 2;
            _error = null;
          });
        } else if (result.isLockedOut) {
          setState(() => _error = 'Too many attempts. Try again later.');
          _shakeController.forward(from: 0);
        } else {
          setState(() => _error = 'Incorrect PIN. Try again.');
          _shakeController.forward(from: 0);
          await Future.delayed(const Duration(milliseconds: 500));
          setState(() => _currentPin = '');
        }
        break;
      case 2:
        setState(() => _step = 3);
        break;
      case 3:
        if (_confirmPin != _newPin) {
          setState(() => _error = 'PINs do not match. Try again.');
          _shakeController.forward(from: 0);
          await Future.delayed(const Duration(milliseconds: 500));
          setState(() {
            _confirmPin = '';
          });
          return;
        }

        setState(() => _saving = true);
        final success = await pinAuthService.changePin(_currentPin, _newPin);
        setState(() => _saving = false);
        if (!mounted) return;

        if (success) {
          AppMessages.success(context, 'PIN changed successfully');
          Navigator.pop(context);
        } else {
          setState(() => _error = 'Failed to change PIN. Try again.');
          _shakeController.forward(from: 0);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dots = _activePin;
    final titles = {
      1: 'Enter current PIN',
      2: 'Create new PIN',
      3: 'Confirm new PIN',
    };
    final subtitles = {
      1: 'Verify your current PIN to continue',
      2: 'Choose a new 6-digit PIN',
      3: 'Re-enter your new PIN to confirm',
    };

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(title: const Text('Change PIN')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final active = i + 1 <= _step;
                return Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.forest : AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text('Step $_step of 3',
                style: const TextStyle(
                    color: AppTheme.mutedForeground, fontSize: 12)),
            const SizedBox(height: 32),
            Text(
              titles[_step]!,
              style: const TextStyle(
                color: AppTheme.foreground,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitles[_step]!,
              style: const TextStyle(
                color: AppTheme.mutedForeground,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 36),
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
                    bgColor = _error != null
                        ? AppTheme.destructive
                        : AppTheme.forest;
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
                            ? (_error != null
                                ? AppTheme.destructive
                                : AppTheme.forest)
                            : const Color(0xFF2A2A2A),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            AnimatedOpacity(
              opacity: _error != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                _error ?? '',
                style: const TextStyle(
                  color: AppTheme.destructive,
                  fontSize: 13,
                ),
              ),
            ),
            if (_saving) ...[
              const SizedBox(height: 20),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.forest),
              ),
            ],
            const Spacer(),
            PayVerifyKeypad(
              onDigit: _onDigit,
              onBackspace: _onBackspace,
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
          ],
        ),
      ),
    );
  }
}
