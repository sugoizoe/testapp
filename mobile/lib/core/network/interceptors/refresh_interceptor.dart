import 'dart:async';

import 'package:dio/dio.dart';

import '../token_storage.dart';

/// 401 Unauthorized durumunda arka planda /auth/refresh çağrısını yapar
/// ve başarısız isteği otomatik olarak tekrarlar.
class RefreshInterceptor extends Interceptor {
  RefreshInterceptor(this._storage, this._dio);

  final TokenStorage _storage;
  final Dio _dio;

  bool _isRefreshing = false;
  final List<_QueuedRequest> _queue = [];

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final requestOptions = err.requestOptions;

    if (statusCode == 401 && !_isRefreshRequest(requestOptions)) {
      final refresh = await _storage.getRefreshToken();
      if (refresh == null || refresh.isEmpty) {
        await _storage.clear();
        return handler.next(err);
      }

      final completer = Completer<Response<dynamic>>();
      _queue.add(_QueuedRequest(
        options: requestOptions,
        completer: completer,
      ));

      if (!_isRefreshing) {
        _isRefreshing = true;
        try {
          await _refreshToken(refresh);

          final newAccess = await _storage.getAccessToken();
          for (final queued in _queue) {
            try {
              final options = queued.options;
              if (newAccess != null && newAccess.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $newAccess';
              }
              final resp = await _dio.fetch<dynamic>(options);
              queued.completer.complete(resp);
            } catch (e) {
              queued.completer.completeError(e);
            }
          }
        } catch (_) {
          await _storage.clear();
          for (final queued in _queue) {
            queued.completer.completeError(err);
          }
        } finally {
          _queue.clear();
          _isRefreshing = false;
        }
      }

      try {
        final result = await completer.future;
        return handler.resolve(result);
      } catch (_) {
        return handler.next(err);
      }
    }

    handler.next(err);
  }

  bool _isRefreshRequest(RequestOptions options) {
    return options.path.contains('/auth/refresh');
  }

  Future<void> _refreshToken(String refreshToken) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
      options: Options(
        headers: {
          'Authorization': null,
        },
      ),
    );

    final data = resp.data;
    if (data == null ||
        data['access_token'] == null ||
        data['refresh_token'] == null) {
      throw DioException(
        requestOptions: resp.requestOptions,
        response: resp,
        type: DioExceptionType.badResponse,
      );
    }

    await _storage.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
  }
}

class _QueuedRequest {
  _QueuedRequest({
    required this.options,
    required this.completer,
  });

  final RequestOptions options;
  final Completer<Response<dynamic>> completer;
}

