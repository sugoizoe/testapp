import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileMediaItem {
  final String url;
  final bool isVideo;

  const ProfileMediaItem({
    required this.url,
    this.isVideo = false,
  });
}

class ProfileState {
  final String fullName;
  final int age;
  final String bio;
  final String avatarUrl;
  final String backgroundUrl;
  final String liveStatus;
  final List<ProfileMediaItem> media;

  const ProfileState({
    required this.fullName,
    required this.age,
    required this.bio,
    required this.avatarUrl,
    required this.backgroundUrl,
    required this.liveStatus,
    required this.media,
  });

  ProfileState copyWith({
    String? fullName,
    int? age,
    String? bio,
    String? avatarUrl,
    String? backgroundUrl,
    String? liveStatus,
    List<ProfileMediaItem>? media,
  }) {
    return ProfileState(
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      backgroundUrl: backgroundUrl ?? this.backgroundUrl,
      liveStatus: liveStatus ?? this.liveStatus,
      media: media ?? this.media,
    );
  }
}

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController()
      : super(
          const ProfileState(
            fullName: 'Deniz Yılmaz',
            age: 27,
            bio:
                'Gün batımında kahve, gece yarısı uzun yürüyüşler ve beklenmedik sohbetler.',
            avatarUrl:
                'https://images.pexels.com/photos/415829/pexels-photo-415829.jpeg',
            backgroundUrl:
                'https://images.pexels.com/photos/1130626/pexels-photo-1130626.jpeg',
            liveStatus: 'Şu an kafedeyim ☕',
            media: [
              ProfileMediaItem(
                url:
                    'https://images.pexels.com/photos/34950/pexels-photo.jpg',
              ),
              ProfileMediaItem(
                url:
                    'https://images.pexels.com/photos/210186/pexels-photo-210186.jpeg',
              ),
              ProfileMediaItem(
                url:
                    'https://images.pexels.com/photos/247431/pexels-photo-247431.jpeg',
              ),
              ProfileMediaItem(
                url:
                    'https://images.pexels.com/photos/572897/pexels-photo-572897.jpeg',
              ),
              ProfileMediaItem(
                url:
                    'https://images.pexels.com/photos/1323550/pexels-photo-1323550.jpeg',
              ),
              ProfileMediaItem(
                url:
                    'https://images.pexels.com/photos/210186/pexels-photo-210186.jpeg',
                isVideo: true,
              ),
            ],
          ),
        );

  // Mock: gelecekte galeriden arka plan seçildiğinde güncellenecek.
  void updateBackground(String newUrl) {
    state = state.copyWith(backgroundUrl: newUrl);
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>(
  (ref) => ProfileController(),
);

