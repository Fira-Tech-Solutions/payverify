import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PayVerifyKeypad extends StatelessWidget {
  final Function(String) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onFingerprintTap;
  final bool showFingerprint;

  const PayVerifyKeypad({
    required this.onDigit,
    required this.onBackspace,
    this.onFingerprintTap,
    this.showFingerprint = false,
    super.key,
  });

  static const _keySize = 70.0;
  static const _gap = 16.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(['1', '2', '3']),
        SizedBox(height: _gap),
        _buildRow(['4', '5', '6']),
        SizedBox(height: _gap),
        _buildRow(['7', '8', '9']),
        SizedBox(height: _gap),
        _buildBottomRow(),
        if (showFingerprint) ...[
          SizedBox(height: _gap),
          _buildFingerprintRow(),
        ],
      ],
    );
  }

  Widget _buildRow(List<String> keys) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: keys
            .map((k) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _gap / 2),
                  child: _GlassKey(
                    label: k,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onDigit(k);
                    },
                  ),
                ))
            .toList(),
      );

  Widget _buildBottomRow() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _gap / 2),
            child: _GlassKey(
              icon: Icons.backspace_outlined,
              iconSize: 22,
              onTap: () {
                HapticFeedback.lightImpact();
                onBackspace();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _gap / 2),
            child: _GlassKey(
              label: '0',
              onTap: () {
                HapticFeedback.lightImpact();
                onDigit('0');
              },
            ),
          ),
          SizedBox(width: _keySize + _gap),
        ],
      );

  Widget _buildFingerprintRow() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _GlassKey(
            icon: Icons.fingerprint,
            iconSize: 28,
            onTap: () {
              HapticFeedback.mediumImpact();
              onFingerprintTap?.call();
            },
          ),
        ],
      );
}

class _GlassKey extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final double? iconSize;
  final VoidCallback? onTap;

  const _GlassKey({
    this.label,
    this.icon,
    this.iconSize,
    this.onTap,
  });

  @override
  State<_GlassKey> createState() => _GlassKeyState();
}

class _GlassKeyState extends State<_GlassKey> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: PayVerifyKeypad._keySize,
              height: PayVerifyKeypad._keySize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _pressed
                    ? Colors.white.withOpacity(0.18)
                    : Colors.white.withOpacity(0.07),
                border: Border.all(
                  color: _pressed
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.12),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_pressed ? 0.1 : 0.25),
                    blurRadius: _pressed ? 4 : 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: widget.label != null
                    ? Text(
                        widget.label!,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w300,
                          color: Colors.white.withOpacity(_pressed ? 1.0 : 0.85),
                          height: 1.0,
                        ),
                      )
                    : Icon(
                        widget.icon,
                        color: Colors.white.withOpacity(_pressed ? 1.0 : 0.6),
                        size: widget.iconSize ?? 22,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
