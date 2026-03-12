import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import 'settings_controller.dart';
import 'widgets/language_bottom_sheet.dart';
import 'widgets/settings_list_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Ayarlar & Gizlilik'),
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'Hesap'),
          SettingsListTile(
            icon: Icons.email_outlined,
            title: 'E-posta',
            subtitle: state.email,
            trailingType: SettingsTrailingType.chevron,
            onTap: () {
              // Profil / e-posta güncelleme akışına yönlendirme
            },
          ),
          SettingsListTile(
            icon: Icons.phone_outlined,
            title: 'Telefon Numarası',
            subtitle: state.phone,
            trailingType: SettingsTrailingType.chevron,
            onTap: () {},
          ),
          SettingsListTile(
            icon: Icons.pause_circle_outline,
            title: 'Hesabı Dondur',
            subtitle: 'Geçici olarak Keşfet\'ten gizlen.',
            trailingType: SettingsTrailingType.switcher,
            value: state.accountFrozen,
            onChanged: (_) => controller.toggleAccountFrozen(),
          ),
          SettingsListTile(
            icon: Icons.delete_forever_rounded,
            title: 'Hesabı Sil',
            subtitle:
                'Tüm verilerin kalıcı olarak silinir. Bu işlem geri alınamaz.',
            danger: true,
            trailingType: SettingsTrailingType.chevron,
            onTap: () {
              // Hesap silme onayı
            },
          ),
          const _SectionDivider(),
          const _SectionHeader(title: 'Gizlilik & Güvenlik'),
          SettingsListTile(
            icon: Icons.location_off_outlined,
            title: 'Mesafemi Gizle',
            showPremiumBadge: true,
            trailingType: SettingsTrailingType.switcher,
            value: state.hideDistance,
            onChanged: (_) => controller.toggleHideDistance(),
          ),
          SettingsListTile(
            icon: Icons.cake_outlined,
            title: 'Yaşımı Gizle',
            showPremiumBadge: true,
            trailingType: SettingsTrailingType.switcher,
            value: state.hideAge,
            onChanged: (_) => controller.toggleHideAge(),
          ),
          SettingsListTile(
            icon: Icons.visibility_off_outlined,
            title: 'Görünmez Mod',
            subtitle: 'Sadece senin beğendiğin kişiler seni görebilir.',
            showPremiumBadge: true,
            trailingType: SettingsTrailingType.switcher,
            value: state.invisibleMode,
            onChanged: (_) => controller.toggleInvisibleMode(),
          ),
          SettingsListTile(
            icon: Icons.shield_moon_outlined,
            title: 'İki Faktörlü Doğrulama',
            subtitle: state.twoFactorEnabled
                ? 'Aktif (Authenticator bağlı)'
                : 'Devre dışı',
            trailingType: SettingsTrailingType.chevron,
            onTap: () {
              // 2FA setup ekranına yönlendirme
            },
          ),
          const _SectionDivider(),
          const _SectionHeader(title: 'Uygulama Tercihleri'),
          SettingsListTile(
            icon: Icons.favorite_outline,
            title: 'Eşleşme Bildirimleri',
            trailingType: SettingsTrailingType.switcher,
            value: state.notifyMatches,
            onChanged: (_) => controller.toggleNotifyMatches(),
          ),
          SettingsListTile(
            icon: Icons.radar_rounded,
            title: 'Datenow Live İstekleri',
            trailingType: SettingsTrailingType.switcher,
            value: state.notifyLive,
            onChanged: (_) => controller.toggleNotifyLive(),
          ),
          SettingsListTile(
            icon: Icons.videocam_rounded,
            title: 'Görüntülü Arama Bildirimleri',
            trailingType: SettingsTrailingType.switcher,
            value: state.notifyCalls,
            onChanged: (_) => controller.toggleNotifyCalls(),
          ),
          SettingsListTile(
            icon: Icons.language_rounded,
            title: 'Dil',
            subtitle: state.language.label,
            trailingType: SettingsTrailingType.chevron,
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => const LanguageBottomSheet(),
              );
            },
          ),
          const _SectionDivider(),
          const _SectionHeader(title: 'Hakkında'),
          SettingsListTile(
            icon: Icons.info_outline_rounded,
            title: 'Hakkında & Yasal Bilgiler',
            trailingType: SettingsTrailingType.chevron,
            onTap: () {},
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.softGrey,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: Colors.white.withValues(alpha:0.08),
      thickness: 1,
      height: 24,
      indent: 16,
      endIndent: 16,
    );
  }
}

