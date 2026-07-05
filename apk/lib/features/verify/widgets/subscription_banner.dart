import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/subscription_provider.dart';
import '../../../theme/app_theme.dart';

class SubscriptionBanner extends ConsumerWidget {
  final SubscriptionBannerInfo? info;

  const SubscriptionBanner({super.key, this.info});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannerInfo = info ?? ref.watch(subscriptionBannerProvider);
    if (bannerInfo == null) return const SizedBox.shrink();

    Color bgColor;
    Color textColor;
    IconData icon;

    switch (bannerInfo.type) {
      case SubscriptionBannerType.trial:
        bgColor = const Color(0xFFFFF3E0);
        textColor = AppTheme.warning;
        icon = Icons.info_outline;
        break;
      case SubscriptionBannerType.grace:
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        icon = Icons.warning_amber_rounded;
        break;
      case SubscriptionBannerType.expired:
        bgColor = AppTheme.danger.withValues(alpha: 0.1);
        textColor = AppTheme.danger;
        icon = Icons.block;
        break;
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/subscription'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: bgColor,
        child: Row(
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                bannerInfo.message,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: textColor),
          ],
        ),
      ),
    );
  }
}
