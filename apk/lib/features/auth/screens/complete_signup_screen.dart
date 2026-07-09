import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/providers.dart';
import '../../../theme/app_theme.dart';

class CompleteSignupScreen extends ConsumerStatefulWidget {
  const CompleteSignupScreen({super.key});

  @override
  ConsumerState<CompleteSignupScreen> createState() =>
      _CompleteSignupScreenState();
}

class _CompleteSignupScreenState extends ConsumerState<CompleteSignupScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final password = _passwordCtrl.text.trim();
    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    if (password != _confirmCtrl.text.trim()) {
      _showError('Passwords do not match');
      return;
    }

    setState(() => _submitting = true);
    final success =
        await ref.read(registrationProvider.notifier).completeSignup(password);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      // Auth provider detects the new user and navigates to PIN setup
    } else {
      final error = ref.read(registrationProvider).error;
      _showError(error ?? 'Signup failed');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(registrationProvider);

    if (regState.userId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/register');
      });
      return const Scaffold(
          backgroundColor: AppTheme.obsidian, body: SizedBox());
    }

    final isLoading = regState.isSubmitting || _submitting;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/payverify_icons/payverify_icon_512x512.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('PayVerify',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('Ethiopian payment verification',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14)),
                ],
              ),
            ),

            // Card area
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Create your account',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      const Text(
                        'Your identity has been verified. Set a password to finalize your account.',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.5),
                      ),
                      const SizedBox(height: 24),

                      // Identity card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.verified_user,
                                    size: 18, color: AppTheme.primary),
                                SizedBox(width: 8),
                                Text('Fayda Identity Verified',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primary)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Registering workspace for owner: ${regState.fetchedName ?? ''}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.foreground),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Authenticated Phone: ${regState.fetchedPhone ?? ''}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _label('Set a password'),
                      _field(_passwordCtrl,
                          hint: 'Min. 6 characters',
                          obscure: _obscurePassword,
                          suffix: IconButton(
                            icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 20,
                                color: AppTheme.textMuted),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          )),
                      const SizedBox(height: 12),
                      _label('Confirm password'),
                      _field(_confirmCtrl,
                          hint: 'Re-enter password',
                          obscure: _obscureConfirm,
                          suffix: IconButton(
                            icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 20,
                                color: AppTheme.textMuted),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          )),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Create Account'),
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
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary)),
      );

  Widget _field(
    TextEditingController ctrl, {
    String hint = '',
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCaps = TextCapitalization.none,
    Widget? suffix,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboardType,
          textCapitalization: textCaps,
          decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
        ),
      );
}
