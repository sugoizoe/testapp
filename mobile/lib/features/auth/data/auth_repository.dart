import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/token_storage.dart';

class AuthRepository {
  AuthRepository({
    required this.dio,
    required this.tokenStorage,
  });

  final Dio dio;
  final TokenStorage tokenStorage;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email.trim(),
        'password': password,
      },
    );

    final data = response.data ?? {};
    final access = data['access_token'] as String?;
    final refresh = data['refresh_token'] as String?;
    if (access == null || refresh == null) {
      throw Exception('Beklenmeyen sunucu yanıtı.');
    }

    await tokenStorage.saveTokens(
      accessToken: access,
      refreshToken: refresh,
    );
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String birthDate,
    required String gender,
    required String targetGenderPreference,
  }) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'email': email.trim(),
        'password': password,
        'full_name': fullName,
        'birth_date': birthDate,
        'gender': gender,
        'target_gender_preference': targetGenderPreference,
      },
    );

    final data = response.data ?? {};
    final access = data['access_token'] as String?;
    final refresh = data['refresh_token'] as String?;
    if (access == null || refresh == null) {
      throw Exception('Beklenmeyen sunucu yanıtı.');
    }

    await tokenStorage.saveTokens(
      accessToken: access,
      refreshToken: refresh,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.read(dioProvider);
  final storage = ref.read(tokenStorageProvider);
  return AuthRepository(
    dio: dio,
    tokenStorage: storage,
  );
});

