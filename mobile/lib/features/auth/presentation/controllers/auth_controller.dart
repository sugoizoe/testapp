import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/validators.dart';
import '../../data/auth_repository.dart';
import '../../../../core/providers/global_providers.dart';

final authControllerProvider =
    AutoDisposeAsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {
    // no-op initial state
  }

  Future<void> login({
    required String email,
    required String password,
    required GoRouter router,
  }) async {
    if (!isValidEmail(email) || !isValidPassword(password)) {
      throw Exception('Lütfen geçerli bir e-posta ve en az 8 karakterli şifre girin.');
    }

    state = const AsyncLoading();
    final repo = ref.read(authRepositoryProvider);

    try {
      await repo.login(email: email, password: password);
      ref.read(authProvider.notifier).setLoggedIn();
      state = const AsyncData(null);
      router.go('/home');
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required DateTime birthDate,
    required String gender,
    required String targetGenderPreference,
    required GoRouter router,
  }) async {
    if (!isValidEmail(email)) {
      throw Exception('Lütfen geçerli bir e-posta adresi girin.');
    }
    if (!isValidPassword(password)) {
      throw Exception('Şifre en az 8 karakter olmalıdır.');
    }
    if (!isAtLeast18YearsOld(birthDate)) {
      throw Exception('Datenow sadece 18 yaş ve üzeri kullanıcılar içindir.');
    }

    state = const AsyncLoading();
    final repo = ref.read(authRepositoryProvider);

    try {
      await repo.register(
        email: email,
        password: password,
        fullName: fullName,
        birthDate: formatBirthDate(birthDate),
        gender: gender,
        targetGenderPreference: targetGenderPreference,
      );
      ref.read(authProvider.notifier).setLoggedIn();
      state = const AsyncData(null);
      router.go('/home');
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
