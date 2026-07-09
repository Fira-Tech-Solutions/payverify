import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../providers/providers.dart';
import '../../../theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _showJoin = false;

  // Join-with-code fields
  final _codeCtrl     = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _joinPhoneCtrl = TextEditingController();
  final _joinPwCtrl   = TextEditingController();
  final _joinConfirmPwCtrl = TextEditingController();
  bool _joinObscure = true;
  bool _joinConfirmObscure = true;

  @override
  void dispose() {
    for (final c in [
      _phoneCtrl, _passwordCtrl, _codeCtrl, _nameCtrl,
      _joinPhoneCtrl, _joinPwCtrl, _joinConfirmPwCtrl,
    ]) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AsyncLoading;
    final error = authState is AsyncError
        ? (authState as AsyncError).error.toString()
        : null;

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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (error != null) ...[
                        _ErrorBanner(error),
                        const SizedBox(height: 16),
                      ],

                      if (!_showJoin) ...[
                        const Text('Sign in',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 20),
                        _label('Phone number'),
                        _field(_phoneCtrl, hint: '09xxxxxxxx',
                            keyboardType: TextInputType.phone),
                        const SizedBox(height: 12),
                        _label('Password'),
                        _field(_passwordCtrl,
                            hint: '••••••••',
                            obscure: _obscure,
                            suffix: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                                  size: 20, color: AppTheme.textMuted),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            )),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: isLoading ? null : _login,
                          child: isLoading
                              ? _loader()
                              : const Text('Sign in'),
                        ),
                        const SizedBox(height: 16),
                        _Divider('or'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _AuthCard(
                                icon: Icons.group_add_rounded,
                                iconColor: const Color(0xFF25D366),
                                title: 'Join as\nCashier',
                                subtitle: 'Have an invite code?',
                                onTap: () =>
                                    setState(() => _showJoin = true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _AuthCard(
                                icon: Icons.store_rounded,
                                iconColor: AppTheme.accent,
                                title: 'Register\nBusiness',
                                subtitle: 'Start verifying payments',
                                onTap: () =>
                                    context.push('/register'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SocialIcon(
                              icon: Icons.telegram,
                              color: const Color(0xFF0088CC),
                              onTap: () => _launchUrl('tg://resolve?domain=pay_verify_support'),
                            ),
                            const SizedBox(width: 20),
                            _SocialIcon(
                              icon: Icons.chat,
                              color: const Color(0xFF25D366),
                              onTap: () => _launchUrl('whatsapp://send?phone=251715673817'),
                            ),
                            const SizedBox(width: 20),
                            _SocialIcon(
                              icon: Icons.phone,
                              color: AppTheme.accent,
                              onTap: () => _launchUrl('tel:+251952052542'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text('Support team',
                              style: TextStyle(
                                  fontSize: 11, color: AppTheme.textMuted)),
                        ),
                      ],

                      if (_showJoin) ...[
                        _BackRow('Join with invite code',
                            () => setState(() => _showJoin = false)),
                        const SizedBox(height: 20),
                        _label('6-character invite code (from your employer)'),
                        _field(_codeCtrl,
                            hint: 'ABC123',
                            textCaps: TextCapitalization.characters),
                        const SizedBox(height: 12),
                        _label('Your name'),
                        _field(_nameCtrl, hint: 'Abebe Bekele'),
                        const SizedBox(height: 12),
                        _label('Your phone number'),
                        _field(_joinPhoneCtrl, hint: '09xxxxxxxx',
                            keyboardType: TextInputType.phone),
                        const SizedBox(height: 12),
                        _label('Set a password'),
                        _field(_joinPwCtrl,
                            hint: '••••••••',
                            obscure: _joinObscure,
                            suffix: IconButton(
                              icon: Icon(_joinObscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                                  size: 20, color: AppTheme.textMuted),
                              onPressed: () =>
                                  setState(() => _joinObscure = !_joinObscure),
                            )),
                        const SizedBox(height: 12),
                        _label('Confirm password'),
                        _field(_joinConfirmPwCtrl,
                            hint: '••••••••',
                            obscure: _joinConfirmObscure,
                            suffix: IconButton(
                              icon: Icon(_joinConfirmObscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                                  size: 20, color: AppTheme.textMuted),
                              onPressed: () =>
                                  setState(() => _joinConfirmObscure = !_joinConfirmObscure),
                            )),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: isLoading ? null : _joinWithCode,
                          child: isLoading
                              ? _loader()
                              : const Text('Join business'),
                        ),
                      ],
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

  void _login() {
    ref.read(authProvider.notifier).login(
          _phoneCtrl.text.trim(),
          _passwordCtrl.text,
        );
  }

  void _joinWithCode() {
    if (_joinPwCtrl.text != _joinConfirmPwCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    ref.read(authProvider.notifier).joinWithCode(
          code:     _codeCtrl.text.trim(),
          name:     _nameCtrl.text.trim(),
          phone:    _joinPhoneCtrl.text.trim(),
          password: _joinPwCtrl.text,
        );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to https URL in browser
      final fallback = url.startsWith('tg://')
          ? 'https://t.me/pay_verify_support'
          : url.startsWith('whatsapp://')
              ? 'https://wa.me/251715673817'
              : url;
      final fallbackUri = Uri.parse(fallback);
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    }
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

  Widget _loader() => const SizedBox(
        height: 20, width: 20,
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
      );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.dangerLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.danger)),
            ),
          ],
        ),
      );
}

class _Divider extends StatelessWidget {
  final String label;
  const _Divider(this.label);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Expanded(child: Divider(color: AppTheme.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textMuted)),
          ),
          const Expanded(child: Divider(color: AppTheme.border)),
        ],
      );
}

class _BackRow extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _BackRow(this.title, this.onBack);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: const Icon(Icons.arrow_back,
                size: 20, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      );
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SocialIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      );
}

class _AuthCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _AuthCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 10),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      height: 1.2)),
              const SizedBox(height: 4),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 10, color: AppTheme.textMuted)),
            ],
          ),
        ),
      );
}
