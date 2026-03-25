import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Handles AES-256-CBC encryption/decryption of sensitive fields.
///
/// The encryption key is generated once and stored in the Android Keystore
/// via [FlutterSecureStorage], so it never appears in plain storage.
class EncryptionService {
  static const _keyStorageKey = 'encryption_key';
  static const _ivStorageKey = 'encryption_iv';

  final FlutterSecureStorage _secureStorage;
  encrypt.Key? _key;
  encrypt.IV? _staticIv; // Kept for legacy decryption support only

  EncryptionService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Initialise the AES key. Generates a new one on first launch.
  Future<void> init() async {
    String? storedKey = await _secureStorage.read(key: _keyStorageKey);
    String? storedIv = await _secureStorage.read(key: _ivStorageKey);

    if (storedKey == null || storedIv == null) {
      // First launch – generate cryptographically secure key & IV.
      final random = Random.secure();
      final keyBytes =
          Uint8List.fromList(List.generate(32, (_) => random.nextInt(256)));
      final ivBytes =
          Uint8List.fromList(List.generate(16, (_) => random.nextInt(256)));

      storedKey = base64Encode(keyBytes);
      storedIv = base64Encode(ivBytes);

      await _secureStorage.write(key: _keyStorageKey, value: storedKey);
      await _secureStorage.write(key: _ivStorageKey, value: storedIv);
    }

    _key = encrypt.Key.fromBase64(storedKey);
    _staticIv = encrypt.IV.fromBase64(storedIv);
  }

  /// Encrypt a plaintext string. Returns "ivBase64:ciphertextBase64".
  String encryptText(String plaintext) {
    if (_key == null) {
      throw StateError('EncryptionService not initialised. Call init() first.');
    }
    
    // Generate a fresh IV for every encryption operation.
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter =
        encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.cbc));
    
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    
    // Format: IV:Ciphertext
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypt back to plaintext. Supports both IV-prefixed and legacy formats.
  String decryptText(String ciphertext) {
    if (_key == null) {
      throw StateError('EncryptionService not initialised. Call init() first.');
    }

    final encrypter =
        encrypt.Encrypter(encrypt.AES(_key!, mode: encrypt.AESMode.cbc));

    // Check if it's the new format (contains a separator).
    if (ciphertext.contains(':')) {
      final parts = ciphertext.split(':');
      if (parts.length == 2) {
        final iv = encrypt.IV.fromBase64(parts[0]);
        return encrypter.decrypt64(parts[1], iv: iv);
      }
    }

    // Fallback to legacy static IV.
    if (_staticIv == null) {
      throw StateError('Legacy IV not found for decryption.');
    }
    return encrypter.decrypt64(ciphertext, iv: _staticIv);
  }

  /// Encrypt a field only if it has a value (non-null, non-empty).
  String? encryptField(String? value) {
    if (value == null || value.isEmpty) return value;
    return encryptText(value);
  }

  /// Decrypt a field only if it has a value (non-null, non-empty).
  String? decryptField(String? value) {
    if (value == null || value.isEmpty) return value;
    return decryptText(value);
  }
}
