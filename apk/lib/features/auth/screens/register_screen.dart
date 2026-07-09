import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/providers.dart';
import '../../../theme/app_theme.dart';
import '../widgets/fayda_verification_modal.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _bizNameCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _bizNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _startVerification() async {
    final bizName = _bizNameCtrl.text.trim();
    if (bizName.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your business name'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final result = await Navigator.push<FaydaVerificationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => FaydaVerificationModal(bizName: bizName),
      ),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result != null) {
      // Store the data returned from the WebView handshake
      ref.read(registrationProvider.notifier).setFaydaData(
            userId: result.userId,
            fetchedName: result.name,
            fetchedPhone: result.phone,
            businessName: bizName,
          );
      if (mounted) context.push('/register/complete');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      const Text('Register your business',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      const Text(
                        'Verify your identity with Fayda (Ethiopian National Digital ID) to get started.',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      _label('Business name'),
                      _field(
                        _bizNameCtrl,
                        hint: 'Dawit General Store',
                        textCaps: TextCapitalization.words,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _startVerification,
                          icon: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.fingerprint, size: 20),
                          label: Text(
                              _loading ? 'Connecting...' : 'Verify Identity with Fayda ID'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Already have an account? Sign in',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13)),
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
