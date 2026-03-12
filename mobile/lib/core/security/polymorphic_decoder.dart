import 'dart:convert';

/// Polymorphic Enigma JSON yapısını çözmek için yardımcı servis.
///
/// Backend ile paylaşılan gizli seed ve cihazın Unix timestamp'ini
/// kullanarak o anki dinamik JSON anahtarlarını tahmin eder.
class PolymorphicDecoder {
  PolymorphicDecoder({
    required this.seed,
    int Function()? nowProvider,
  }) : _nowProvider = nowProvider ?? _defaultNowProvider;

  final String seed;
  final int Function() _nowProvider;

  static int _defaultNowProvider() =>
      DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

  /// Backend tarafındaki algoritma ile senkronize olacak şekilde
  /// anahtar çözümleme mantığı burada uygulanmalıdır.
  Map<String, dynamic> decodeRaw(Map<String, dynamic> obfuscated) {
    // İleride seed + _nowProvider() ile key türetme kullanılacak.
    ignoreForNow(_nowProvider);
    return obfuscated;
  }

  static void ignoreForNow(int Function() fn) => fn();

  /// Genel amaçlı decode + model mapping helper'ı.
  T decodeToModel<T>(
    Map<String, dynamic> obfuscated,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final plain = decodeRaw(obfuscated);
    return fromJson(plain);
  }

  /// Bazı durumlarda backend'den string JSON gelebilir.
  T decodeJsonStringToModel<T>(
    String jsonString,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final map =
        (jsonDecode(jsonString) as Map).cast<String, dynamic>();
    return decodeToModel(map, fromJson);
  }
}

