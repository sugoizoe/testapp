import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import 'dio_client.dart';
import 'token_storage.dart';

enum SocketEventType {
  liveStatus,
  matchFound,
  callSignal,
  unknown,
}

class SocketEvent {
  SocketEvent({
    required this.type,
    required this.payload,
  });

  final SocketEventType type;
  final Map<String, dynamic> payload;
}

class WebSocketClient {
  WebSocketClient({
    required this.baseWsUrl,
    required this.tokenStorage,
  });

  final String baseWsUrl;
  final TokenStorage tokenStorage;

  WebSocketChannel? _channel;
  final _eventsController = StreamController<SocketEvent>.broadcast();

  Stream<SocketEvent> get events => _eventsController.stream;

  bool get isConnected => _channel != null;

  Future<void> connect() async {
    if (_channel != null) return;

    final access = await tokenStorage.getAccessToken();
    final uri = Uri.parse(baseWsUrl).replace(
      queryParameters: {
        if (access != null && access.isNotEmpty) 'access_token': access,
      },
    );

    final channel = WebSocketChannel.connect(uri);
    _channel = channel;

    channel.stream.listen(
      (message) {
        try {
          final decoded = jsonDecode(message as String) as Map<String, dynamic>;
          final typeStr = decoded['type'] as String? ?? '';
          final payload =
              (decoded['payload'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

          _eventsController.add(
            SocketEvent(
              type: _mapType(typeStr),
              payload: payload,
            ),
          );
        } catch (_) {
          // Sessizce yut, telemetry ileride eklenebilir.
        }
      },
      onError: (_) {
        // İleride retry/backoff stratejisi eklenebilir.
        disconnect();
      },
      onDone: () {
        disconnect();
      },
    );
  }

  Future<void> disconnect() async {
    await _channel?.sink.close(ws_status.normalClosure);
    _channel = null;
  }

  Future<void> send(Map<String, dynamic> data) async {
    final channel = _channel;
    if (channel == null) return;
    channel.sink.add(jsonEncode(data));
  }

  SocketEventType _mapType(String raw) {
    switch (raw) {
      case 'live_status':
        return SocketEventType.liveStatus;
      case 'match_found':
        return SocketEventType.matchFound;
      case 'call_signal':
        return SocketEventType.callSignal;
      default:
        return SocketEventType.unknown;
    }
  }
}

String get _defaultWsUrl {
  if (kIsWeb) return 'ws://localhost:8080/ws';
  if (Platform.isAndroid) return 'ws://10.0.2.2:8080/ws';
  return 'ws://localhost:8080/ws';
}

final String kBaseWsUrl = const String.fromEnvironment('WS_BASE_URL') != ''
    ? const String.fromEnvironment('WS_BASE_URL')
    : _defaultWsUrl;

final webSocketClientProvider = Provider<WebSocketClient>((ref) {
  final storage = ref.read(tokenStorageProvider);
  return WebSocketClient(
    baseWsUrl: kBaseWsUrl,
    tokenStorage: storage,
  );
});

final socketEventsProvider = StreamProvider<SocketEvent>((ref) async* {
  final client = ref.read(webSocketClientProvider);
  await client.connect();
  yield* client.events;
});

