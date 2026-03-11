import 'package:dio/dio.dart';

import '../token_storage.dart';

/// Her isteğe Authorization: Bearer <access_token> header'ını ekler.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage);

  final TokenStorage _storage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final access = await _storage.getAccessToken();
    if (access != null && access.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $access';
    }
    handler.next(options);
  }
}

