import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage {
  en('English'),
  es('Español'),
  fr('Français'),
  de('Deutsch'),
  zh('中文'),
  ru('Русский'),
  tr('Türkçe');

  const AppLanguage(this.label);
  final String label;
}

class SettingsState {
  // Account
  final String email;
  final String phone;
  final bool accountFrozen;

  // Privacy (premium hooks)
  final bool hideDistance;
  final bool hideAge;
  final bool invisibleMode;
  final bool twoFactorEnabled;

  // Notifications
  final bool notifyMatches;
  final bool notifyLive;
  final bool notifyCalls;

  // Language
  final AppLanguage language;

  const SettingsState({
    required this.email,
    required this.phone,
    required this.accountFrozen,
    required this.hideDistance,
    required this.hideAge,
    required this.invisibleMode,
    required this.twoFactorEnabled,
    required this.notifyMatches,
    required this.notifyLive,
    required this.notifyCalls,
    required this.language,
  });

  SettingsState copyWith({
    String? email,
    String? phone,
    bool? accountFrozen,
    bool? hideDistance,
    bool? hideAge,
    bool? invisibleMode,
    bool? twoFactorEnabled,
    bool? notifyMatches,
    bool? notifyLive,
    bool? notifyCalls,
    AppLanguage? language,
  }) {
    return SettingsState(
      email: email ?? this.email,
      phone: phone ?? this.phone,
      accountFrozen: accountFrozen ?? this.accountFrozen,
      hideDistance: hideDistance ?? this.hideDistance,
      hideAge: hideAge ?? this.hideAge,
      invisibleMode: invisibleMode ?? this.invisibleMode,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      notifyMatches: notifyMatches ?? this.notifyMatches,
      notifyLive: notifyLive ?? this.notifyLive,
      notifyCalls: notifyCalls ?? this.notifyCalls,
      language: language ?? this.language,
    );
  }
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController()
      : super(
          const SettingsState(
            email: 'deniz@example.com',
            phone: '+90 555 000 00 00',
            accountFrozen: false,
            hideDistance: false,
            hideAge: false,
            invisibleMode: false,
            twoFactorEnabled: false,
            notifyMatches: true,
            notifyLive: true,
            notifyCalls: true,
            language: AppLanguage.tr,
          ),
        );

  void toggleHideDistance() {
    state = state.copyWith(hideDistance: !state.hideDistance);
  }

  void toggleHideAge() {
    state = state.copyWith(hideAge: !state.hideAge);
  }

  void toggleInvisibleMode() {
    state = state.copyWith(invisibleMode: !state.invisibleMode);
  }

  void toggleNotifyMatches() {
    state = state.copyWith(notifyMatches: !state.notifyMatches);
  }

  void toggleNotifyLive() {
    state = state.copyWith(notifyLive: !state.notifyLive);
  }

  void toggleNotifyCalls() {
    state = state.copyWith(notifyCalls: !state.notifyCalls);
  }

  void toggleAccountFrozen() {
    state = state.copyWith(accountFrozen: !state.accountFrozen);
  }

  void setLanguage(AppLanguage lang) {
    state = state.copyWith(language: lang);
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>(
  (ref) => SettingsController(),
);

