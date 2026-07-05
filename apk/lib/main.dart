import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'features/app_shell.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/pin_setup_screen.dart';
import 'features/auth/screens/pin_lock_screen.dart';
import 'features/splash/screens/splash_screen.dart';
import 'features/subscription/screens/subscription_screen.dart';
import 'features/subscription/screens/plans_screen.dart';
import 'features/subscription/screens/payment_screen.dart';
import 'features/subscription/screens/telebirr_webview_screen.dart';
import 'features/subscription/screens/subscription_success_screen.dart';
import 'features/subscription/screens/payment_history_screen.dart';
import 'features/dashboard/screens/trends_screen.dart';
import 'features/dashboard/screens/export_screen.dart';
import 'providers/providers.dart';
import 'providers/pin_provider.dart';
import 'services/api/api_client.dart';
import 'services/auth/pin_auth_service.dart';
import 'services/local_db/local_db.dart';
import 'services/sms/sms_listener_service.dart';
import 'models/transaction.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // Lock to portrait (market environment)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: AppTheme.primary,
    statusBarIconBrightness: Brightness.light,
  ));

  await LocalDb.init();
  runApp(const ProviderScope(child: PayVerifyApp()));
  FlutterNativeSplash.remove();
}

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/auth', builder: (_, __) => const _RootRedirect()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/pin-setup', builder: (_, __) => const PinSetupScreen()),
    GoRoute(
      path: '/pin-lock',
      builder: (context, _) => PinLockScreen(
        onUnlocked: () => GoRouter.of(context).go('/app'),
      ),
    ),
    GoRoute(path: '/app', builder: (_, __) => const AppShell()),
    GoRoute(path: '/subscription', builder: (_, __) => const SubscriptionScreen()),
    GoRoute(path: '/subscription/plans', builder: (_, __) => const PlansScreen()),
    GoRoute(
      path: '/subscription/payment',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return PaymentScreen(
          tier: extra['tier'] as String? ?? 'STARTER',
          periodMonths: extra['periodMonths'] as int? ?? 1,
        );
      },
    ),
    GoRoute(
      path: '/subscription/telebirr',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return TeleBirrWebViewScreen(
          toPayUrl: extra['toPayUrl'] as String? ?? '',
          outTradeNo: extra['outTradeNo'] as String? ?? '',
          tier: extra['tier'] as String? ?? 'STARTER',
          periodMonths: extra['periodMonths'] as int? ?? 1,
          amount: (extra['amount'] as num?)?.toDouble() ?? 0,
        );
      },
    ),
    GoRoute(
      path: '/subscription/success',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return SubscriptionSuccessScreen(
          tier: extra['tier'] as String? ?? 'STARTER',
          periodMonths: extra['periodMonths'] as int? ?? 1,
          amount: (extra['amount'] as num?)?.toDouble() ?? 0,
        );
      },
    ),
    GoRoute(path: '/subscription/history', builder: (_, __) => const PaymentHistoryScreen()),
    GoRoute(path: '/trends', builder: (_, __) => const TrendsScreen()),
    GoRoute(path: '/export', builder: (_, __) => const ExportScreen()),
  ],
);

class PayVerifyApp extends ConsumerStatefulWidget {
  const PayVerifyApp({super.key});

  @override
  ConsumerState<PayVerifyApp> createState() => _PayVerifyAppState();
}

class _PayVerifyAppState extends ConsumerState<PayVerifyApp>
    with WidgetsBindingObserver {
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      if (_backgroundedAt != null) {
        final elapsed = DateTime.now().difference(_backgroundedAt!);
        if (elapsed.inSeconds >= 30) {
          final user = ref.read(authProvider).valueOrNull;
          if (user != null) {
            _router.go('/pin-lock');
          }
        }
      }
      _backgroundedAt = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    api.onAuthExpired = () {
      ref.read(authProvider.notifier).logout();
    };

    ref.listen(authProvider, (_, next) {
      next.when(
        data: (user) async {
          if (user != null) {
            _startSmsListener(ref);
            final pinSetup = await pinAuthService.isPinSetup;
            if (!pinSetup) {
              _router.go('/pin-setup');
            } else {
              _router.go('/pin-lock');
            }
          } else {
            _router.go('/login');
          }
        },
        loading: () {},
        error: (_, __) => _router.go('/login'),
      );
    });

    return MaterialApp.router(
      title: 'PayVerify',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }

  void _startSmsListener(WidgetRef ref) {
    final sms = SmsListenerService();
    sms.onBankSmsReceived = (parsed) {
      final user = localDb.getUser();
      if (user == null) return;
      final tx = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        transactionId: parsed.transactionId,
        amount: parsed.amount,
        senderName: parsed.senderName,
        senderPhone: parsed.senderPhone,
        paymentMethod: parsed.paymentMethod,
        status: TxStatus.pending,
        timestamp: DateTime.now(),
        businessId: user.businessId,
        rawSms: parsed.rawSms,
      );
      ref.read(transactionsProvider.notifier).addFromSms(tx);
    };
    sms.startListening();
  }
}

class _RootRedirect extends ConsumerWidget {
  const _RootRedirect();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return auth.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 56, color: Colors.white),
              SizedBox(height: 16),
              Text('PayVerify',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700)),
              SizedBox(height: 32),
              CircularProgressIndicator(color: Colors.white54),
            ],
          ),
        ),
      ),
      error: (_, __) {
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => context.go('/login'));
        return const SizedBox();
      },
      data: (user) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (user != null) {
            final pinSetup = await pinAuthService.isPinSetup;
            context.go(pinSetup ? '/pin-lock' : '/pin-setup');
          } else {
            context.go('/login');
          }
        });
        return const SizedBox();
      },
    );
  }
}
