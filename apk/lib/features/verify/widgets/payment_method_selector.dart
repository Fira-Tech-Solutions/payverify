import 'package:flutter/material.dart';
import '../../../models/transaction.dart';
import '../../../theme/app_theme.dart';

class PaymentMethodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const PaymentMethodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PaymentMethod.all
          .map((method) => _MethodChip(
                method: method,
                isSelected: method == selected,
                onTap: () => onChanged(method),
              ))
          .toList(),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String method;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodChip({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  IconData _iconFor(String m) {
    switch (m) {
      case PaymentMethod.teleBirr:  return Icons.phone_android;
      case PaymentMethod.cbe:       return Icons.account_balance;
      case PaymentMethod.awash:     return Icons.account_balance;
      case PaymentMethod.dashen:    return Icons.account_balance;
      case PaymentMethod.abyssinia: return Icons.account_balance;
      case PaymentMethod.amole:     return Icons.wallet;
      case PaymentMethod.helloCash: return Icons.wallet;
      default:                      return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _iconFor(method),
              size: 15,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              method,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
