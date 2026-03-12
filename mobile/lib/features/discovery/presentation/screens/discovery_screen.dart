import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/discovery_models.dart';
import '../providers/discovery_providers.dart';
import '../widgets/live_status_list.dart';
import '../widgets/swipe_card_item.dart';

class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stackState = ref.watch(discoveryStackProvider);
    final mediaQuery = MediaQuery.of(context);
    const floatingNavHeight = 64.0;
    const floatingNavVerticalMargin = 16.0;
    const extraSafety = 16.0;
    final swiperBottomPadding = floatingNavHeight +
        floatingNavVerticalMargin +
        mediaQuery.padding.bottom +
        extraSafety;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF070716),
              Color(0xFF050510),
              Color(0xFF050513),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              const LiveStatusList(),
              const SizedBox(height: 12),
              Expanded(
                child: stackState.when(
                  data: (profiles) => _buildSwiper(
                    context,
                    ref,
                    profiles,
                    swiperBottomPadding,
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accentPurple,
                    ),
                  ),
                  error: (_, __) => _buildSwiper(
                    context,
                    ref,
                    ref.read(discoveryProfilesProvider),
                    swiperBottomPadding,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwiper(
    BuildContext context,
    WidgetRef ref,
    List<DiscoveryProfile> profiles,
    double bottomPadding,
  ) {
    if (profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.explore_off_rounded,
              size: 64,
              color: AppColors.softGrey.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Şimdilik kimse yok',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.softGrey,
                  ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () =>
                  ref.read(discoveryStackProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Yenile'),
            ),
          ],
        ),
      );
    }

    final notifier = ref.read(discoveryStackProvider.notifier);

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPadding),
      child: AppinioSwiper(
        cardCount: profiles.length,
        backgroundCardCount: 2,
        swipeOptions: const SwipeOptions.symmetric(
          horizontal: true,
          vertical: false,
        ),
        onEnd: () {},
        onSwipeEnd: (previousIndex, targetIndex, activity) {
          if (previousIndex >= 0 && previousIndex < profiles.length) {
            final profile = profiles[previousIndex];
            final action = activity.direction == AxisDirection.right
                ? 'like'
                : 'dislike';
            notifier.swipe(profile, action);
          }
        },
        cardBuilder: (context, index) {
          final profile = profiles[index];
          return SwipeCardItem(
            profile: profile,
            onPass: () => notifier.swipe(profile, 'dislike'),
            onLike: () => notifier.swipe(profile, 'like'),
            onSuperLike: () => notifier.swipe(profile, 'like'),
          );
        },
      ),
    );
  }
}
