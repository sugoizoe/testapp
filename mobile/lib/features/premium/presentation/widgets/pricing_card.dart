import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../premium_controller.dart';

class PricingCard extends StatelessWidget {
  const PricingCard({
    super.key,
    required this.id,
    required this.title,
    required this.priceText,
    required this.subtitle,
    this.isPopular = false,
    required this.selected,
    required this.onTap,
  });

  final PremiumPlanId id;
  final String title;
  final String priceText;
  final String subtitle;
  final bool isPopular;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor =
        selected ? AppColors.accentPurpleSoft : Colors.white.withValues(alpha:0.12);
    final bgColor = selected
        ? AppColors.deepCharcoal.withValues(alpha:0.9)
        : AppColors.darkBackground.withValues(alpha:0.7);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.4),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  priceText,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.accentPurpleSoft,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.softGrey,
                  ),
                ),
              ],
            ),
            if (isPopular)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurpleSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'En Popüler',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

