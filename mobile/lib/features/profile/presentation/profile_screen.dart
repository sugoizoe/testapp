import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import 'profile_controller.dart';
import 'widgets/media_grid_section.dart';
import 'widgets/profile_header_section.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arka plan fotoğrafı
          Image.network(
            state.backgroundUrl,
            fit: BoxFit.cover,
          ),
          // Gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black26,
                  Colors.black87,
                ],
              ),
            ),
          ),
          // İçerik
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: ProfileHeaderSection(state: state),
                ),
                SliverToBoxAdapter(
                  child: MediaGridSection(media: state.media),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

