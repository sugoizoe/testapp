import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/token_storage.dart';

class ChatWsState {
  final bool isConnected;
  final List<String> messages;
  final String? error;

  ChatWsState({
    required this.isConnected,
    required this.messages,
    this.error,
  });

  ChatWsState copyWith({
    bool? isConnected,
    List<String>? messages,
    String? error,
    bool clearError = false,
  }) {
    return ChatWsState(
      isConnected: isConnected ?? this.isConnected,
      messages: messages ?? this.messages,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChatWsNotifier extends StateNotifier<ChatWsState> {
  final TokenStorage _tokenStorage;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isDisposed = false;

  ChatWsNotifier(this._tokenStorage)
      : super(ChatWsState(isConnected: false, messages: []));

  Future<void> connect() async {
    if (_isDisposed) return;
    
    final token = await _tokenStorage.getAccessToken() ?? "dummy_token";

    // Adjust URI scheme from http to ws
    final wsUrl = kBaseUrl.replaceFirst('http', 'ws').replaceFirst('https', 'wss');
    final uri = Uri.parse('$wsUrl/ws?token=$token');

    try {
      _channel = WebSocketChannel.connect(uri);
      state = state.copyWith(isConnected: true, clearError: true);

      _subscription = _channel?.stream.listen(
        (message) {
          if (_isDisposed) return;
          state = state.copyWith(
            messages: [...state.messages, message.toString()],
          );
        },
        onError: (err) {
          if (_isDisposed) return;
          state = state.copyWith(
            isConnected: false,
            error: err.toString(),
          );
          _reconnect();
        },
        onDone: () {
          if (_isDisposed) return;
          state = state.copyWith(
             isConnected: false,
             error: 'Connection closed',
          );
          _reconnect();
        },
      );
    } catch (e) {
      state = state.copyWith(isConnected: false, error: e.toString());
      _reconnect();
    }
  }

  void _reconnect() {
    if (_isDisposed) return;
    Future.delayed(const Duration(seconds: 3), () {
      if (!state.isConnected) {
        connect();
      }
    });
  }

  void sendMessage(String message) {
    if (state.isConnected && _channel != null) {
      _channel!.sink.add(message);
    } else {
      state = state.copyWith(error: 'Cannot send message: not connected');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}

final chatWsProvider =
    StateNotifierProvider.autoDispose<ChatWsNotifier, ChatWsState>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final notifier = ChatWsNotifier(tokenStorage);
  
  // start connecting immediately
  notifier.connect();
  
  return notifier;
});
