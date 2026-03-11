import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/theme/app_theme.dart';

class MatchAnimationScreen extends StatelessWidget {
  const MatchAnimationScreen({
    super.key,
    required this.currentUserAvatar,
    required this.matchedUserAvatar,
  });

  final String currentUserAvatar;
  final String matchedUserAvatar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Lottie flame background (asset yolu mock, projeye eklenmeli)
          Positioned.fill(
            child: Opacity(
              opacity: 0.9,
              child: Lottie.asset(
                'assets/animations/dark_purple_flame.json',
                fit: BoxFit.cover,
                repeat: true,
              ),
            ),
          ),
          // Hafif karartma
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 48),
                Text(
                  'Eşleştiniz!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.accentPurpleSoft,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(
                            color: AppColors.accentPurple,
                            blurRadius: 24,
                          ),
                        ],
                      ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _AvatarCircle(
                          imageUrl: currentUserAvatar,
                          alignment: const Offset(-60, 0),
                        ),
                        _AvatarCircle(
                          imageUrl: matchedUserAvatar,
                          alignment: const Offset(60, 0),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Backend üzerinden call initiate akışı tetiklenecek.
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text(
                            '5 Dakikalık Aramayı Başlat',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Sonra bakarım',
                          style: TextStyle(
                            color: AppColors.softGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.imageUrl,
    required this.alignment,
  });

  final String imageUrl;
  final Offset alignment;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: alignment,
      child: Container(
        width: 110,
        height: 110,
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
          padding: const EdgeInsets.all(4),
          child: ClipOval(
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

