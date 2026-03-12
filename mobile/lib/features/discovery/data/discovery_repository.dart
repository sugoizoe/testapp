import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/security/polymorphic_decoder.dart';
import '../domain/discovery_models.dart';

class DiscoveryRepository {
  DiscoveryRepository({
    required this.dio,
    required this.decoder,
  });

  final Dio dio;
  final PolymorphicDecoder decoder;

  Future<List<DiscoveryProfile>> getNearby({
    double radiusKm = 10,
    int limit = 50,
  }) async {
    final response = await dio.get<List<dynamic>>(
      '/discovery/nearby',
      queryParameters: {
        'radius_km': radiusKm,
        'limit': limit,
      },
    );
    final rawList = response.data ?? [];

    final result = <DiscoveryProfile>[];
    for (final item in rawList) {
      if (item is Map<String, dynamic>) {
        final plain = decoder.decodeRaw(Map<String, dynamic>.from(item));
        result.add(_parseProfile(plain));
      }
    }

    return result;
  }

  static DiscoveryProfile _parseProfile(Map<String, dynamic> plain) {
    final id = plain['user_id'] as String? ?? plain['id'] as String? ?? '';
    final att = plain['attributes'] is Map
        ? Map<String, dynamic>.from(plain['attributes'] as Map)
        : <String, dynamic>{};
    final imageUrl = att['avatar_url'] as String? ??
        att['image_url'] as String? ??
        plain['image_url'] as String? ??
        'https://images.pexels.com/photos/415829/pexels-photo-415829.jpeg';
    final interestsRaw = att['interests'];
    final interests = interestsRaw is List
        ? (interestsRaw).map((e) => e.toString()).toList()
        : <String>[];

    return DiscoveryProfile(
      id: id,
      fullName: plain['full_name'] as String? ?? '',
      age: (plain['age'] as num?)?.toInt() ?? 0,
      distanceKm: (plain['distance_km'] as num?)?.toDouble() ?? 0,
      imageUrl: imageUrl,
      interests: interests.isNotEmpty
          ? interests
          : (plain['bio'] as String?)
                  ?.split(RegExp(r'[,\s]+'))
                  .where((s) => s.isNotEmpty)
                  .take(3)
                  .toList() ??
              [],
    );
  }

  /// Beğeni (like) veya pas (dislike) gönderir. Eşleşme varsa [SwipeResult.isMatch] true döner.
  Future<SwipeResult> swipe(String targetId, String action) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/discovery/swipe',
      data: {'target_id': targetId, 'action': action},
    );
    final data = response.data ?? {};
    return SwipeResult(
      isMatch: data['is_match'] as bool? ?? false,
      matchId: data['match_id'] as String?,
    );
  }
}

class SwipeResult {
  const SwipeResult({required this.isMatch, this.matchId});
  final bool isMatch;
  final String? matchId;
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

