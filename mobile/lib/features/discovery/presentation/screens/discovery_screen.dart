import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/discovery_remote_providers.dart';
import '../widgets/live_status_list.dart';
import '../widgets/swipe_card_item.dart';

class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(discoveryRemoteProfilesProvider);

    return profilesAsync.when(
      data: (profiles) {
        return Scaffold(
          backgroundColor: AppColors.darkBackground,
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                const LiveStatusList(),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AppinioSwiper(
                      cardCount: profiles.length,
                      backgroundCardCount: 2,
                      swipeOptions: const SwipeOptions.symmetric(
                        horizontal: true,
                        vertical: false,
                      ),
                      cardBuilder: (context, index) {
                        final profile = profiles[index];
                        return SwipeCardItem(profile: profile);
                      },
                    ),
                  ),
                ),
                const _BottomNavBar(),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(
          child: Text(
            'Keşif akışı yüklenemedi. Lütfen tekrar deneyin.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.softGrey),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.deepCharcoal.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavIcon(icon: Icons.radar_rounded, active: true),
          _NavIcon(icon: Icons.favorite_outline),
          _NavIcon(icon: Icons.person_outline),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, this.active = false});

  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      color: active ? AppColors.accentPurpleSoft : AppColors.softGrey,
    );
  }
}

