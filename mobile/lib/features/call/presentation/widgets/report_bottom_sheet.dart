import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ReportBottomSheet extends StatelessWidget {
  const ReportBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.deepCharcoal.withValues(alpha:0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Text(
            'Kullanıcıyı Şikayet Et',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const _ReportTile(label: 'Nudity', subtitle: 'Müstehcen / çıplak içerik'),
          const _ReportTile(label: 'Harassment', subtitle: 'Taciz, tehdit veya zorbalık'),
          const _ReportTile(label: 'Spam', subtitle: 'Reklam veya istenmeyen içerik'),
          const _ReportTile(label: 'Scam', subtitle: 'Dolandırıcılık girişimi'),
          const SizedBox(height: 8),
          Text(
            'Gerektiğinde moderasyon ekibimiz sizinle iletişime geçebilir.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.softGrey,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({
    required this.label,
    required this.subtitle,
  });

  final String label;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.softGrey,
            ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: AppColors.softGrey,
      ),
      onTap: () {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Şikayet kaydedildi: $label'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }
}

