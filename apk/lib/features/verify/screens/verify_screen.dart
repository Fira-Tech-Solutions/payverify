import 'dart:async' show Timer;
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChrome, SystemUiOverlayStyle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/providers.dart';
import '../../../providers/subscription_provider.dart';
import '../../../providers/notifications_provider.dart';
import '../../../models/notification.dart';
import '../../../models/transaction.dart';
import '../../../services/local_db/local_db.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/app_messages.dart';
import '../widgets/result_sheet.dart';

class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key});

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen>
    with SingleTickerProviderStateMixin {
  final _manualController = TextEditingController();
  final _scannerController = MobileScannerController();
  final _plansPageController = PageController(viewportFraction: 0.85);
  Timer? _plansAutoScrollTimer;
  bool _torchOn = false;
  bool _scanPaused = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _startPlansAutoScroll();
  }

  void _startPlansAutoScroll() {
    _plansAutoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_plansPageController.hasClients) return;
      final maxScroll = _plansPageController.position.maxScrollExtent;
      final current = _plansPageController.offset;
      final next = current >= maxScroll ? 0.0 : current + 220.0;
      _plansPageController.animateTo(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _plansAutoScrollTimer?.cancel();
    _plansPageController.dispose();
    _manualController.dispose();
    _scannerController.dispose();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  void _onQrDetected(BarcodeCapture capture) {
    if (_scanPaused) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    _scanPaused = true;
    _verify(code);
  }

  Future<void> _verify(String code) async {
    final subStatus = ref.read(subscriptionProvider).valueOrNull;
    if (subStatus != null && subStatus.isExpired) {
      _showSubscriptionExpiredSheet();
      return;
    }

    await ref.read(verifyProvider.notifier).verify(code);
    final result = ref.read(verifyProvider);
    if (!mounted) return;

    if (result.state == VerifyState.success && result.transaction != null) {
      await _showResult(result.transaction!);
    } else if (result.state == VerifyState.error) {
      _showError(result.errorMessage ?? 'Verification failed');
    }
    _scanPaused = false;
    ref.read(verifyProvider.notifier).reset();
  }

  Future<void> _showResult(Transaction tx) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ResultSheet(transaction: tx),
    );
  }

  void _showError(String msg) {
    AppMessages.error(context, msg);
  }

  void _showSubscriptionExpiredSheet() {
    final user = ref.read(authProvider).valueOrNull;
    final isOwner = user?.isOwner ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.block, size: 48, color: AppTheme.destructive),
            const SizedBox(height: 16),
            const Text(
              'Subscription Expired',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              isOwner
                  ? 'Your subscription has expired. Renew to continue verifying payments.'
                  : 'Subscription expired. Contact your employer to renew.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppTheme.mutedForeground),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (isOwner) context.push('/subscription/plans');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.forest,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  isOwner ? 'Renew Subscription' : 'OK',
                  style: const TextStyle(color: Color(0xFF061008)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showSmsImportSheet() {
    final user = ref.read(authProvider).valueOrNull;
    final pending = localDb
        .getTransactions(businessId: user?.businessId)
        .where((t) => t.status == TxStatus.pending)
        .take(10)
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('SMS Payments',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const Spacer(),
                Text('${pending.length} pending',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.forest)),
              ],
            ),
          ),
          if (pending.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.sms_outlined, color: AppTheme.textMuted, size: 40),
                  SizedBox(height: 12),
                  Text('No pending SMS payments',
                      style: TextStyle(color: AppTheme.mutedForeground, fontSize: 14)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pending.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: AppTheme.border, height: 1),
              itemBuilder: (_, i) {
                final tx = pending[i];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: AppTheme.mutedForeground,
                      size: 20,
                    ),
                  ),
                  title: Text('ETB ${tx.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 14)),
                  subtitle: Text('${tx.paymentMethod} · ${tx.transactionId}',
                      style: const TextStyle(
                          color: AppTheme.mutedForeground, fontSize: 11)),
                  trailing: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _verify(tx.transactionId);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.forest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Use',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF061008))),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _openQrScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _QrScannerScreen(
          scannerController: _scannerController,
          onDetected: (code) {
            Navigator.of(context).pop();
            _verify(code);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final verifyState = ref.watch(verifyProvider);
    final isLoading = verifyState.state == VerifyState.processing;
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final subAsync = ref.watch(subscriptionProvider);
    final currentTier = subAsync.whenOrNull(data: (s) => s.tier);

    return Scaffold(
      backgroundColor: AppTheme.obsidian,
      body: Stack(
        children: [
          // ── Gradient header background ─────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 180,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.forestDark, AppTheme.obsidian],
                  stops: [0.0, 0.4],
                ),
              ),
            ),
          ),

          // ── Scrollable content ────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── App Header ────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.gold,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/payverify_icons/payverify_icon_512x512.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('PayVerify',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.foreground)),
                    ),
                    if (ref.watch(authProvider).valueOrNull?.isOwner == true)
                      _NotificationBell(),
                  ],
                ),

                // ── Subscription Plans ────────────────────────────
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text('Subscription Plans',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.push('/subscription/plans'),
                      child: const Text('View All',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.gold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                plansAsync.when(
                  loading: () => const SizedBox(
                    height: 130,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (plans) => SizedBox(
                    height: 130,
                    child: PageView.builder(
                      controller: _plansPageController,
                      itemCount: plans.length,
                      itemBuilder: (_, i) {
                        final plan = plans[i];
                        final isCurrent = plan.tier == currentTier;
                        final isPopular = plan.tier == 'BUSINESS';
                        return GestureDetector(
                          onTap: () => context.push('/subscription/plans'),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isCurrent
                                    ? AppTheme.gold
                                    : isPopular
                                        ? AppTheme.forest
                                        : AppTheme.border,
                                width: isCurrent ? 1.5 : 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(plan.nameEn,
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: isCurrent
                                                  ? AppTheme.gold
                                                  : AppTheme.foreground)),
                                    ),
                                    if (isCurrent)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.gold.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('CURRENT',
                                            style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.gold)),
                                      )
                                    else if (isPopular)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.forest.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text('POPULAR',
                                            style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.forest)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('ETB ${plan.monthlyPrice.toStringAsFixed(0)}/mo',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.foreground)),
                                const SizedBox(height: 4),
                                Text('${plan.cashierDisplay} cashiers · ${plan.locationDisplay} locations',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.mutedForeground)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // ── Transaction Verification Card ──────────────────
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.border),
                  ),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Transaction Verification',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      const Text(
                          'Enter a transaction reference to verify payment.',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.mutedForeground)),
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.obsidianLight,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppTheme.border),
                        ),
                        child: TextField(
                          controller: _manualController,
                          textCapitalization:
                              TextCapitalization.characters,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1),
                          decoration: const InputDecoration(
                            hintText: 'Transaction Reference',
                            hintStyle: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w400),
                            prefixIcon: Icon(Icons.receipt_long,
                                color: AppTheme.textMuted, size: 18),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                          ),
                          onSubmitted: (_) {
                            if (!isLoading) {
                              _verify(_manualController.text);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: isLoading
                            ? null
                            : () => _verify(_manualController.text),
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: AppTheme.forest,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isLoading)
                                const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: Color(0xFF061008),
                                        strokeWidth: 2))
                              else ...[
                                const Icon(Icons.shield_outlined,
                                    size: 18,
                                    color: Color(0xFF061008)),
                                const SizedBox(width: 8),
                                const Text('Verify Transaction',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF061008))),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Quick Action Buttons ───────────────────────────
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        iconBg: const Color(0xFF14101E),
                        icon: Icons.qr_code_scanner,
                        iconColor: const Color(0xFF7C6FF7),
                        name: 'Scan',
                        sub: 'QR Code',
                        onTap: _openQrScanner,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionCard(
                        iconBg: const Color(0xFF0E1A2E),
                        icon: Icons.photo_library_outlined,
                        iconColor: const Color(0xFF4A9EFF),
                        name: 'Upload',
                        sub: 'Receipt',
                        onTap: () => context.push('/verify/receipt'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionCard(
                        iconBg: const Color(0xFF0E1A14),
                        icon: Icons.sms_outlined,
                        iconColor: AppTheme.forest,
                        name: 'SMS',
                        sub: 'Import',
                        onTap: () {
                          if (Platform.isAndroid) {
                            _showSmsImportSheet();
                          } else {
                            AppMessages.info(context, 'SMS import is not available on iOS');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Full-screen QR Scanner ───────────────────────────────────────────────────
class _QrScannerScreen extends StatefulWidget {
  final MobileScannerController scannerController;
  final void Function(String code) onDetected;

  const _QrScannerScreen({
    required this.scannerController,
    required this.onDetected,
  });

  @override
  State<_QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<_QrScannerScreen> {
  bool _paused = false;
  bool _torchOn = false;

  void _onDetect(BarcodeCapture capture) {
    if (_paused) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    _paused = true;
    widget.onDetected(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: widget.scannerController,
            onDetect: _onDetect,
          ),
          CustomPaint(
            painter: _ScanOverlayPainter(),
            child: const SizedBox.expand(),
          ),
          Positioned(
            top: 48,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xCC0E1612),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
          Positioned(
            top: 48,
            right: 16,
            child: GestureDetector(
              onTap: () {
                setState(() => _torchOn = !_torchOn);
                widget.scannerController.toggleTorch();
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xCC0E1612),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Icon(
                  _torchOn ? Icons.flash_on : Icons.flash_off,
                  color: _torchOn ? Colors.yellow : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, color: Colors.white54, size: 18),
                  SizedBox(height: 6),
                  Text(
                    'Point camera at the QR code on the\npayment screenshot or receipt',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat card widget ─────────────────────────────────────────────────────────
// ── Action card widget ───────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String name;
  final String sub;
  final VoidCallback onTap;

  const _ActionCard({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 8),
              Text(name,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              Text(sub,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF6B6358))),
            ],
          ),
        ),
      );
}

// ── Scanner overlay painter ──────────────────────────────────────────────────
class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    final cutoutSize = size.width * 0.7;
    final cutoutLeft = (size.width - cutoutSize) / 2;
    final cutoutTop = (size.height - cutoutSize) / 2 - 40;
    final cutout = RRect.fromRectAndRadius(
      Rect.fromLTWH(cutoutLeft, cutoutTop, cutoutSize, cutoutSize),
      const Radius.circular(12),
    );
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(cutout)
        ..fillType = PathFillType.evenOdd,
      paint,
    );

    final cornerPaint = Paint()
      ..color = AppTheme.gold
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const len = 24.0;
    final r = cutout.outerRect;

    canvas.drawPath(
        Path()
          ..moveTo(r.left, r.top + len)
          ..lineTo(r.left, r.top)
          ..lineTo(r.left + len, r.top),
        cornerPaint);
    canvas.drawPath(
        Path()
          ..moveTo(r.right - len, r.top)
          ..lineTo(r.right, r.top)
          ..lineTo(r.right, r.top + len),
        cornerPaint);
    canvas.drawPath(
        Path()
          ..moveTo(r.left, r.bottom - len)
          ..lineTo(r.left, r.bottom)
          ..lineTo(r.left + len, r.bottom),
        cornerPaint);
    canvas.drawPath(
        Path()
          ..moveTo(r.right - len, r.bottom)
          ..lineTo(r.right, r.bottom)
          ..lineTo(r.right, r.bottom - len),
        cornerPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Notification bell with unread badge ─────────────────────────────────────
class _NotificationBell extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return GestureDetector(
      onTap: () => _showNotificationsSheet(context, ref),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppTheme.foreground,
              size: 20,
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppTheme.destructive,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void _showNotificationsSheet(BuildContext context, WidgetRef ref) {
  final notifications = ref.read(notificationsProvider);
  ref.read(notificationsProvider.notifier).markAllRead();

  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _NotificationsSheet(notifications: notifications),
  );
}

class _NotificationsSheet extends StatelessWidget {
  final List<AppNotification> notifications;
  const _NotificationsSheet({required this.notifications});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('Notifications',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.foreground)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: notifications.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_none,
                            color: AppTheme.mutedForeground, size: 48),
                        SizedBox(height: 12),
                        Text('No notifications yet',
                            style: TextStyle(
                                color: AppTheme.mutedForeground, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: controller,
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const Divider(
                        color: AppTheme.border, height: 1, indent: 20),
                    itemBuilder: (_, i) {
                      final n = notifications[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 6),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: n.type == AppNotificationType.transaction
                                ? const Color(0xFF0E1A14)
                                : n.type == AppNotificationType.subscription
                                    ? const Color(0xFF1A1A0E)
                                    : AppTheme.card,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            n.type == AppNotificationType.transaction
                                ? Icons.receipt_long
                                : n.type == AppNotificationType.subscription
                                    ? Icons.card_membership
                                    : Icons.info_outline,
                            color: n.type == AppNotificationType.transaction
                                ? AppTheme.forest
                                : n.type == AppNotificationType.subscription
                                    ? AppTheme.gold
                                    : AppTheme.mutedForeground,
                            size: 20,
                          ),
                        ),
                        title: Text(n.title,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.foreground)),
                        subtitle: Text(n.body,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.mutedForeground)),
                        trailing: Text(
                          _timeAgo(n.createdAt),
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.mutedForeground),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
