import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/security/polymorphic_decoder.dart';
import '../../discovery/presentation/providers/discovery_providers.dart';

class DiscoveryRepository {
  DiscoveryRepository({
    required this.dio,
    required this.decoder,
  });

  final Dio dio;
  final PolymorphicDecoder decoder;

  Future<List<DiscoveryProfile>> getNearby() async {
    final response = await dio.get<List<dynamic>>('/discovery/nearby');
    final rawList = response.data ?? [];

    final result = <DiscoveryProfile>[];
    for (final item in rawList) {
      if (item is Map<String, dynamic>) {
        final plain = decoder.decodeRaw(item);
        result.add(
          DiscoveryProfile(
            id: plain['id'] as String,
            fullName: plain['full_name'] as String,
            age: plain['age'] as int,
            distanceKm: (plain['distance_km'] as num).toDouble(),
            imageUrl: plain['image_url'] as String,
            interests: (plain['interests'] as List<dynamic>)
                .map((e) => e.toString())
                .toList(),
          ),
        );
      }
    }

    return result;
  }
}

final polymorphicDecoderProvider = Provider<PolymorphicDecoder>((ref) {
  // Seed backend ile paylaşılmalı; şimdilik sabit bir değer ile ilerliyoruz.
  return PolymorphicDecoder(seed: 'datenow-shared-seed');
});

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  final dio = ref.read(dioProvider);
  final decoder = ref.read(polymorphicDecoderProvider);
  return DiscoveryRepository(
    dio: dio,
    decoder: decoder,
  );
});

