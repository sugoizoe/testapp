import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiscoveryProfile {
  final String id;
  final String fullName;
  final int age;
  final double distanceKm;
  final String imageUrl;
  final List<String> interests;

  const DiscoveryProfile({
    required this.id,
    required this.fullName,
    required this.age,
    required this.distanceKm,
    required this.imageUrl,
    required this.interests,
  });
}

class LiveStatusUser {
  final String id;
  final String name;
  final String avatarUrl;

  const LiveStatusUser({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });
}

final liveStatusListProvider = Provider<List<LiveStatusUser>>((ref) {
  return const [
    LiveStatusUser(
      id: '1',
      name: 'Deniz',
      avatarUrl:
          'https://images.pexels.com/photos/614810/pexels-photo-614810.jpeg',
    ),
    LiveStatusUser(
      id: '2',
      name: 'Efe',
      avatarUrl:
          'https://images.pexels.com/photos/2379005/pexels-photo-2379005.jpeg',
    ),
    LiveStatusUser(
      id: '3',
      name: 'Mert',
      avatarUrl:
          'https://images.pexels.com/photos/91227/pexels-photo-91227.jpeg',
    ),
    LiveStatusUser(
      id: '4',
      name: 'Lara',
      avatarUrl:
          'https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg',
    ),
    LiveStatusUser(
      id: '5',
      name: 'Selin',
      avatarUrl:
          'https://images.pexels.com/photos/415829/pexels-photo-415829.jpeg',
    ),
  ];
});

final discoveryProfilesProvider = Provider<List<DiscoveryProfile>>((ref) {
  return const [
    DiscoveryProfile(
      id: 'p1',
      fullName: 'Deniz Yılmaz',
      age: 27,
      distanceKm: 3.4,
      imageUrl:
          'https://images.pexels.com/photos/1130626/pexels-photo-1130626.jpeg',
      interests: ['Futbol', 'Satranç', 'Performans Araçları'],
    ),
    DiscoveryProfile(
      id: 'p2',
      fullName: 'Efe Demir',
      age: 29,
      distanceKm: 5.2,
      imageUrl:
          'https://images.pexels.com/photos/1704488/pexels-photo-1704488.jpeg',
      interests: ['Felsefe', 'Varoluşçuluk', 'Kahve'],
    ),
    DiscoveryProfile(
      id: 'p3',
      fullName: 'Lara Kaya',
      age: 25,
      distanceKm: 1.8,
      imageUrl:
          'https://images.pexels.com/photos/415829/pexels-photo-415829.jpeg',
      interests: ['Yoga', 'Minimalizm', 'Fotoğraf'],
    ),
    DiscoveryProfile(
      id: 'p4',
      fullName: 'Arda Çelik',
      age: 31,
      distanceKm: 8.7,
      imageUrl:
          'https://images.pexels.com/photos/2379005/pexels-photo-2379005.jpeg',
      interests: ['Koşu', 'Teknoloji', 'Oyun Teorisi'],
    ),
    DiscoveryProfile(
      id: 'p5',
      fullName: 'Selin Öztürk',
      age: 26,
      distanceKm: 2.1,
      imageUrl:
          'https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg',
      interests: ['Senaryo Yazımı', 'Tiyatro', 'Psikoloji'],
    ),
  ];
});

