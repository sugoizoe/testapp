import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// SRP-6a tarzı verifier hesaplama servisi.
///
/// Gerçek parametreler (N, g, hash algoritması) backend ile
/// senkronize edilmelidir.
class SrpService {
  SrpService({
    required this.N,
    required this.g,
    HashAlgorithm? hashAlgorithm,
  }) : hashAlgorithm = hashAlgorithm ?? Sha256();

  /// Büyük asal modül (backend ile paylaşılan).
  final BigInt N;

  /// Generator.
  final BigInt g;

  final HashAlgorithm hashAlgorithm;

  /// Verilen salt ve parola için SRP verifier üretir.
  ///
  /// Dönüş değeri hex string olarak temsil edilir.
  Future<String> computeVerifier({
    required String username,
    required String password,
    required List<int> salt,
  }) async {
    // x = H(s | H(username:password))
    final up = utf8.encode('$username:$password');
    final upHash = await hashAlgorithm.hash(up);

    final sPlusUp = <int>[...salt, ...upHash.bytes]
      
      ;

    final xHash = await hashAlgorithm.hash(sPlusUp);
    final x = _bytesToBigInt(xHash.bytes);

    // v = g^x mod N
    final v = g.modPow(x, N);
    return v.toRadixString(16);
  }

  /// Kriptografik olarak güçlü rastgele salt üretir.
  Future<List<int>> generateSalt({int length = 16}) async {
    final rand = Random.secure();
    return List<int>.generate(length, (_) => rand.nextInt(256));
  }

  BigInt _bytesToBigInt(List<int> bytes) {
    var result = BigInt.zero;
    for (final b in bytes) {
      result = (result << 8) | BigInt.from(b);
    }
    return result;
  }
}

