import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/discovery_providers.dart';

class SwipeCardItem extends StatelessWidget {
  const SwipeCardItem({
    super.key,
    required this.profile,
  });

  final DiscoveryProfile profile;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            profile.imageUrl,
            fit: BoxFit.cover,
          ),
          // Alt kısımda siyah/mor degrade overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _InfoSection(profile: profile),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: _VideoBadge(),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.profile});

  final DiscoveryProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${profile.fullName}, ${profile.age}',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${profile.distanceKm.toStringAsFixed(1)} km uzakta',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.softGrey,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: -4,
          children: profile.interests.take(3).map((interest) {
            return Chip(
              label: Text(
                interest,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.black.withOpacity(0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _VideoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accentPurpleSoft, width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.videocam_rounded,
            color: AppColors.accentPurpleSoft,
            size: 18,
          ),
          SizedBox(width: 6),
          Text(
            '5 dk',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

