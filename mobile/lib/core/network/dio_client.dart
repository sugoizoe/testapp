import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'token_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/refresh_interceptor.dart';

String get _defaultBaseUrl {
  if (kIsWeb) return 'http://localhost:8080/api/v1';
  if (Platform.isAndroid) return 'http://10.0.2.2:8080/api/v1';
  return 'http://127.0.0.1:8080/api/v1';
}

final String kBaseUrl = const String.fromEnvironment('API_BASE_URL') != ''
    ? const String.fromEnvironment('API_BASE_URL')
    : _defaultBaseUrl;

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.read(tokenStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(storage),
    RefreshInterceptor(storage, dio),
  ]);
  return dio;
});
