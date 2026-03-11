import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../profile_controller.dart';

class MediaGridSection extends StatelessWidget {
  const MediaGridSection({
    super.key,
    required this.media,
  });

  final List<ProfileMediaItem> media;

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.8,
        ),
        itemCount: media.length,
        itemBuilder: (context, index) {
          final item = media[index];
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  item.url,
                  fit: BoxFit.cover,
                ),
                if (item.isVideo)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                    child: const Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          color: AppColors.accentPurpleSoft,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

