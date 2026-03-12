import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/discovery_models.dart';

class SwipeCardItem extends StatelessWidget {
  const SwipeCardItem({
    super.key,
    required this.profile,
    this.onPass,
    this.onLike,
    this.onSuperLike,
  });

  final DiscoveryProfile profile;
  final VoidCallback? onPass;
  final VoidCallback? onLike;
  final VoidCallback? onSuperLike;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.55),
            offset: const Offset(0, 26),
            blurRadius: 46,
            spreadRadius: -16,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              profile.imageUrl,
              fit: BoxFit.cover,
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha:0.12),
                      const Color(0xFF050511).withValues(alpha:0.65),
                      Colors.black.withValues(alpha:0.96),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 18,
              right: 18,
              child: _LiveStatusBadge(),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 110,
              child: _GlassInfoCard(profile: profile),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 26,
              child: _ActionButtonsRow(
                onPass: onPass,
                onLike: onLike,
                onSuperLike: onSuperLike,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassInfoCard extends StatelessWidget {
  const _GlassInfoCard({required this.profile});

  final DiscoveryProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bio =
        profile.interests.take(3).join(' • '); // basit mock bio hissi

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withValues(alpha:0.08),
            border: Border.all(
              color: Colors.white.withValues(alpha:0.18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: profile.fullName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                          TextSpan(
                            text: ', ${profile.age}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.softGrey.withValues(alpha:0.9),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${profile.distanceKm.toStringAsFixed(1)} km',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.softGrey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                bio,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.softGrey.withValues(alpha:0.95),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveStatusBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha:0.22),
                Colors.white.withValues(alpha:0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha:0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentPurpleSoft.withValues(alpha:0.4),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.brightness_1,
                color: Colors.greenAccent,
                size: 8,
              ),
              SizedBox(width: 6),
              Text(
                'Şu an kafedeyim ☕',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButtonsRow extends StatelessWidget {
  const _ActionButtonsRow({
    this.onPass,
    this.onLike,
    this.onSuperLike,
  });

  final VoidCallback? onPass;
  final VoidCallback? onLike;
  final VoidCallback? onSuperLike;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          icon: Icons.close_rounded,
          gradientColors: const [Color(0xFF2B2B30), Color(0xFF15151A)],
          accentColor: Colors.redAccent,
          size: 62,
          onTap: onPass,
        ),
        const SizedBox(width: 18),
        _ActionButton(
          icon: Icons.star_rounded,
          gradientColors: const [AppColors.accentPurple, AppColors.accentPurpleSoft],
          accentColor: Colors.white,
          size: 70,
          onTap: onSuperLike,
        ),
        const SizedBox(width: 18),
        _ActionButton(
          icon: Icons.favorite_rounded,
          gradientColors: const [Color(0xFF2B2B30), Color(0xFF15151A)],
          accentColor: Colors.pinkAccent,
          size: 62,
          onTap: onLike,
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.gradientColors,
    required this.accentColor,
    required this.size,
    this.onTap,
  });

  final IconData icon;
  final List<Color> gradientColors;
  final Color accentColor;
  final double size;
  final VoidCallback? onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  void _setPressed(bool value) {
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.7),
                offset: const Offset(0, 18),
                blurRadius: 38,
                spreadRadius: -18,
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha:0.16),
              width: 1.2,
            ),
          ),
          child: Center(
            child: Icon(
              widget.icon,
              color: widget.accentColor,
              size: widget.size * 0.45,
            ),
          ),
        ),
      ),
    );
  }
}

