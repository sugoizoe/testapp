import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../settings_controller.dart';

class LanguageBottomSheet extends ConsumerWidget {
  const LanguageBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.deepCharcoal,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Dil Seç',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          ...AppLanguage.values.map(
            (lang) {
              final selected = state.language == lang;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _LanguageFlag(lang: lang),
                title: Text(
                  lang.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                trailing: selected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.accentPurpleSoft,
                      )
                    : null,
                onTap: () {
                  controller.setLanguage(lang);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LanguageFlag extends StatelessWidget {
  const _LanguageFlag({required this.lang});

  final AppLanguage lang;

  @override
  Widget build(BuildContext context) {
    String emoji;
    switch (lang) {
      case AppLanguage.en:
        emoji = '🇺🇸';
        break;
      case AppLanguage.es:
        emoji = '🇪🇸';
        break;
      case AppLanguage.fr:
        emoji = '🇫🇷';
        break;
      case AppLanguage.de:
        emoji = '🇩🇪';
        break;
      case AppLanguage.zh:
        emoji = '🇨🇳';
        break;
      case AppLanguage.ru:
        emoji = '🇷🇺';
        break;
      case AppLanguage.tr:
        emoji = '🇹🇷';
        break;
    }
    return Text(
      emoji,
      style: const TextStyle(fontSize: 20),
    );
  }
}

