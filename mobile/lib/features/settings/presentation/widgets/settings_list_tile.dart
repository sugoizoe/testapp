import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

enum SettingsTrailingType {
  none,
  switcher,
  chevron,
  premiumLock,
}

class SettingsListTile extends StatelessWidget {
  const SettingsListTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingType = SettingsTrailingType.none,
    this.value,
    this.onChanged,
    this.onTap,
    this.showPremiumBadge = false,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final SettingsTrailingType trailingType;
  final bool? value;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onTap;
  final bool showPremiumBadge;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = danger ? AppColors.danger : Colors.white;

    Widget? trailing;
    switch (trailingType) {
      case SettingsTrailingType.switcher:
        trailing = _PurpleSwitch(
          value: value ?? false,
          onChanged: onChanged,
        );
        break;
      case SettingsTrailingType.chevron:
        trailing = const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.softGrey,
        );
        break;
      case SettingsTrailingType.premiumLock:
        trailing = const Icon(
          Icons.lock_outline_rounded,
          color: AppColors.accentPurpleSoft,
        );
        break;
      case SettingsTrailingType.none:
        trailing = null;
        break;
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: danger ? AppColors.danger : AppColors.softGrey,
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textColor,
                            fontWeight:
                                danger ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (showPremiumBadge)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accentPurpleSoft.withValues(alpha:0.2),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.accentPurpleSoft,
                              width: 0.8,
                            ),
                          ),
                          child: const Text(
                            'Premium',
                            style: TextStyle(
                              color: AppColors.accentPurpleSoft,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.softGrey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 12),
              trailing,
            ],
          ],
        ),
      ),
    );
  }
}

class _PurpleSwitch extends StatelessWidget {
  const _PurpleSwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.white,
      activeTrackColor: AppColors.accentPurple,
      inactiveTrackColor: AppColors.deepCharcoal,
      inactiveThumbColor: AppColors.softGrey,
    );
  }
}

