import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/discovery_providers.dart';

class LiveStatusList extends ConsumerWidget {
  const LiveStatusList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(liveStatusListProvider);

    if (users.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final user = users[index];
          return Column(
            children: [
              _GradientAvatar(url: user.avatarUrl),
              const SizedBox(height: 6),
              Text(
                user.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.softGrey,
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GradientAvatar extends StatelessWidget {
  const _GradientAvatar({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.accentPurple,
            AppColors.accentPurpleSoft,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.darkBackground,
            image: DecorationImage(
              image: NetworkImage(url),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

