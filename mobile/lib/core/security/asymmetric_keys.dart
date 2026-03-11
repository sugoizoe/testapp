import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Cihazda saklanan asimetrik anahtar çifti (örn. Ed25519 / X25519)
/// için yardımcı fonksiyonlar.
class AsymmetricKeyService {
  AsymmetricKeyService({
    FlutterSecureStorage? secureStorage,
    this.keyPairType = KeyPairType.ed25519,
  }) : _storage = secureStorage ?? const FlutterSecureStorage();

  static const _privateKeyKey = 'device_private_key';
  static const _publicKeyKey = 'device_public_key';

  final FlutterSecureStorage _storage;
  final KeyPairType keyPairType;

  Future<KeyPair> getOrCreateKeyPair() async {
    final existingPrivate = await _storage.read(key: _privateKeyKey);
    final existingPublic = await _storage.read(key: _publicKeyKey);

    final algorithm = _algorithmForType();

    if (existingPrivate != null && existingPublic != null) {
      final privateBytes = base64Decode(existingPrivate);
      return algorithm.newKeyPairFromSeed(privateBytes);
    }

    // Ed25519 returns SimpleKeyPair; cast needed for extractPrivateKeyBytes.
    final keyPair = await algorithm.newKeyPair() as SimpleKeyPair;
    final privateKey = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();
    final publicKeyBytes = (publicKey).bytes;

    await _storage.write(
      key: _privateKeyKey,
      value: base64Encode(privateKey),
    );
    await _storage.write(
      key: _publicKeyKey,
      value: base64Encode(publicKeyBytes),
    );

    return keyPair;
  }

  Future<List<int>> getPublicKeyBytes() async {
    final public = await _storage.read(key: _publicKeyKey);
    if (public == null) return [];
    return base64Decode(public);
  }

  SignatureAlgorithm _algorithmForType() {
    switch (keyPairType) {
      case KeyPairType.ed25519:
        return Ed25519();
    }
  }
}

enum KeyPairType {
  ed25519,
  // İleride X25519 vb. eklenebilir.
}

