import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/discovery_repository.dart';
import '../../domain/discovery_models.dart' show DiscoveryProfile;

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

/// Mock liste (API yokken veya hata durumunda yedek).
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

/// Backend'den yüklenen keşfet listesi ve swipe aksiyonu. API hatasında mock listeye düşer.
final discoveryStackProvider =
    StateNotifierProvider<DiscoveryStackNotifier, AsyncValue<List<DiscoveryProfile>>>(
        (ref) {
  final repo = ref.read(discoveryRepositoryProvider);
  final mock = ref.read(discoveryProfilesProvider);
  return DiscoveryStackNotifier(repo: repo, fallbackList: mock);
});

class DiscoveryStackNotifier
    extends StateNotifier<AsyncValue<List<DiscoveryProfile>>> {
  DiscoveryStackNotifier({
    required DiscoveryRepository repo,
    required List<DiscoveryProfile> fallbackList,
  })  : _repo = repo,
        _fallbackList = fallbackList,
        super(const AsyncValue.loading()) {
    _load();
  }

  final DiscoveryRepository _repo;
  final List<DiscoveryProfile> _fallbackList;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.getNearby();
      state = AsyncValue.data(list.isEmpty ? _fallbackList : list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      state = AsyncValue.data(_fallbackList);
    }
  }

  /// Yeniden yükle (aşağı çekerek veya boş liste sonrası).
  void refresh() => _load();

  /// Beğeni (like) veya pas (dislike) gönderir, listeden kaldırır. Eşleşme varsa [SwipeResult] döner.
  Future<SwipeResult?> swipe(DiscoveryProfile profile, String action) async {
    final list = state.valueOrNull ?? [];
    if (list.isEmpty) return null;
    try {
      final result = await _repo.swipe(profile.id, action);
      state = AsyncValue.data(
        list.where((p) => p.id != profile.id).toList(),
      );
      return result;
    } catch (_) {
      return null;
    }
  }
}

