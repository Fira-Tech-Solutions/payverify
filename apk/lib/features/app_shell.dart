import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../providers/subscription_provider.dart';
import '../theme/app_theme.dart';
import '../services/realtime/realtime_service.dart';
import '../services/sync/offline_sync_manager.dart';
import 'verify/screens/verify_screen.dart';
import 'verify/widgets/subscription_banner.dart';
import 'history/screens/history_screen.dart';
import 'workers/screens/workers_screen.dart';
import 'analytics/screens/analytics_screen.dart';
import 'settings/screens/settings_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;
  bool _wsConnected = false;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    await realtimeService.connect();
    realtimeService.onConnectionChange((c) {
      if (mounted) setState(() => _wsConnected = c);
    });

    realtimeService.onTransaction((tx) {
      ref.read(transactionsProvider.notifier).addFromSms(tx);
    });

    await offlineSync.init();

    try {
      await ref.read(transactionsProvider.notifier).sync();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;
    if (user == null) return const SizedBox();

    final isOwner = user.isOwner || user.isManager;

    final screens = [
      const VerifyScreen(),
      const HistoryScreen(),
      if (isOwner) const AnalyticsScreen(),
      if (isOwner) const WorkersScreen(),
      const SettingsScreen(),
    ];

    final navItems = [
      const BottomNavigationBarItem(
          icon: Icon(Icons.qr_code_scanner), label: 'Verify'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.history), label: 'History'),
      if (isOwner)
        const BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart), label: 'Analytics'),
      if (isOwner)
        const BottomNavigationBarItem(
            icon: Icon(Icons.people), label: 'Workers'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.settings), label: 'Settings'),
    ];

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          Consumer(
            builder: (context, ref, _) {
              final bannerInfo = ref.watch(subscriptionBannerProvider);
              if (bannerInfo == null) return const SizedBox.shrink();
              return SubscriptionBanner(info: bannerInfo);
            },
          ),
          Expanded(
            child: IndexedStack(
              index: _index.clamp(0, screens.length - 1),
              children: screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_wsConnected)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              color: AppTheme.warningLight,
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, size: 13, color: AppTheme.warning),
                  SizedBox(width: 6),
                  Text('Offline — verifications queued',
                      style: TextStyle(
                          fontSize: 11, color: AppTheme.warning)),
                ],
              ),
            ),
          BottomNavigationBar(
            currentIndex: _index.clamp(0, navItems.length - 1),
            onTap: (i) => setState(() => _index = i),
            items: navItems,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    realtimeService.disconnect();
    offlineSync.dispose();
    super.dispose();
  }
}
