import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/discovery_repository.dart';
import 'discovery_providers.dart';

/// Gerçek /discovery/nearby endpoint'ini çağıran provider.
final discoveryRemoteProfilesProvider =
    FutureProvider<List<DiscoveryProfile>>((ref) async {
  final repo = ref.read(discoveryRepositoryProvider);
  return repo.getNearby();
});

