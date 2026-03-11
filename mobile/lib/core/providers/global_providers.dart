import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/dio_client.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isPremium;
  final bool isShadowbanned;
  final bool isLoading;

  const AuthState({
    required this.isAuthenticated,
    required this.isPremium,
    required this.isShadowbanned,
    required this.isLoading,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isPremium,
    bool? isShadowbanned,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isPremium: isPremium ?? this.isPremium,
      isShadowbanned: isShadowbanned ?? this.isShadowbanned,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  static const unknown = AuthState(
    isAuthenticated: false,
    isPremium: false,
    isShadowbanned: false,
    isLoading: true,
  );
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this.ref) : super(AuthState.unknown) {
    _loadInitial();
  }

  final Ref ref;

  Future<void> _loadInitial() async {
    final storage = ref.read(tokenStorageProvider);
    final access = await storage.getAccessToken();
    // Şimdilik sadece access token varlığına göre auth durumunu belirliyoruz (mock).
    final isAuth = access != null && access.isNotEmpty;
    state = state.copyWith(
      isAuthenticated: isAuth,
      isLoading: false,
    );
  }

  void setLoggedOut() {
    state = state.copyWith(
      isAuthenticated: false,
      isPremium: false,
      isShadowbanned: false,
    );
  }

  void setPremium(bool value) {
    state = state.copyWith(isPremium: value);
  }

  void setShadowbanned(bool value) {
    state = state.copyWith(isShadowbanned: value);
  }
}

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final dioClientProvider = Provider<Dio>((ref) {
  // Re-export core dioProvider for global use.
  return ref.read(dioProvider);
});

final authProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});

