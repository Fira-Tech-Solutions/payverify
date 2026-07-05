import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/subscription_provider.dart';
import '../../../services/api/api_client.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/app_messages.dart';

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  bool _isYearly = false;

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(subscriptionPlansProvider);
    final subAsync = ref.watch(subscriptionProvider);
    final currentTier = subAsync.whenOrNull(data: (s) => s.tier);

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Plan')),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    color: AppTheme.destructive, size: 40),
                const SizedBox(height: 12),
                Text(
                  e is ApiException ? e.message : 'Could not load plans',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppTheme.foreground, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        data: (plans) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _isYearly = false),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isYearly
                              ? AppTheme.accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            'Monthly',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: !_isYearly
                                  ? const Color(0xFF0A1A0A)
                                  : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _isYearly = true),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isYearly
                              ? AppTheme.accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Yearly',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _isYearly
                                    ? const Color(0xFF0A1A0A)
                                    : AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _isYearly
                                    ? const Color(0xFF0A1A0A)
                                        .withValues(alpha: 0.3)
                                    : AppTheme.accent,
                                borderRadius:
                                    BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Save 2mo',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
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
            const SizedBox(height: 20),
            ...plans.map((plan) {
              final isCurrentPlan = plan.tier == currentTier;
              return _PlanCard(
                plan: plan,
                isYearly: _isYearly,
                isCurrentPlan: isCurrentPlan,
                onSelect: () {
                  if (isCurrentPlan) {
                    AppMessages.info(context, 'You are already on this plan');
                    return;
                  }
                  final periodMonths = _isYearly ? 12 : 1;
                  context.push('/subscription/payment', extra: {
                    'tier': plan.tier,
                    'periodMonths': periodMonths,
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final dynamic plan;
  final bool isYearly;
  final bool isCurrentPlan;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.plan,
    required this.isYearly,
    required this.isCurrentPlan,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isPopular = plan.tier == 'BUSINESS';
    final price =
        isYearly ? plan.yearlyPrice : plan.monthlyPrice;
    final period = isYearly ? '/year' : '/month';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPopular ? AppTheme.accent : AppTheme.border,
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(11)),
              ),
              child: const Text(
                'MOST POPULAR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A1A0A),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      plan.nameEn,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (isCurrentPlan) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accent
                              .withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'CURRENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ETB ${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: 4),
                      child: Text(
                        period,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${plan.cashierDisplay} cashiers \u00b7 ${plan.locationDisplay} locations',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ...plan.features.map((f) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              size: 16,
                              color: AppTheme.accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              f,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color:
                                      AppTheme.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        isCurrentPlan ? null : onSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentPlan
                          ? AppTheme.border
                          : (isPopular
                              ? AppTheme.accent
                              : AppTheme.cardBg),
                      foregroundColor: isCurrentPlan
                          ? AppTheme.textMuted
                          : (isPopular
                              ? const Color(0xFF0A1A0A)
                              : AppTheme.textPrimary),
                      side: isPopular || isCurrentPlan
                          ? null
                          : const BorderSide(
                              color: AppTheme.border),
                      padding:
                          const EdgeInsets.symmetric(
                              vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8)),
                    ),
                    child: Text(
                      isCurrentPlan
                          ? 'Current Plan'
                          : (isPopular
                              ? 'Get Started'
                              : 'Choose ${plan.nameEn}'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
