import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Handles PIN creation, verification, biometric auth, and lockout.
///
/// The PIN is hashed with SHA-256 before storage so the original
/// PIN is never persisted. All secrets go through [FlutterSecureStorage]
/// which is backed by the Android Keystore.
class AuthService {
  static const _pinHashKey = 'pin_hash';
  static const _pinSaltKey = 'pin_salt';
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _failedAttemptsKey = 'failed_attempts';
  static const _lockoutUntilKey = 'lockout_until';

  static const int maxAttempts = 3;
  static const int lockoutSeconds = 30;

  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;

  AuthService({
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuth,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _localAuth = localAuth ?? LocalAuthentication();

  /// Check if a PIN has been set (i.e. first-run completed).
  Future<bool> isPinSet() async {
    final hash = await _secureStorage.read(key: _pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  /// Ensure a salt exists for hashing.
  Future<String> _getOrGenerateSalt() async {
    String? salt = await _secureStorage.read(key: _pinSaltKey);
    if (salt == null) {
      final bytes = encrypt.IV.fromSecureRandom(16).bytes;
      salt = base64Encode(bytes);
      await _secureStorage.write(key: _pinSaltKey, value: salt);
    }
    return salt;
  }

  /// Set the master PIN. Stores salted SHA-256 hash.
  Future<void> setPin(String pin) async {
    final salt = await _getOrGenerateSalt();
    final hash = _hashPin(pin, salt);
    await _secureStorage.write(key: _pinHashKey, value: hash);
    await _resetFailedAttempts();
  }

  /// Verify a PIN attempt.
  Future<bool> verifyPin(String pin) async {
    if (await isLockedOut()) return false;

    final storedHash = await _secureStorage.read(key: _pinHashKey);
    final salt = await _getOrGenerateSalt();
    final attemptHash = _hashPin(pin, salt);

    if (storedHash == attemptHash) {
      await _resetFailedAttempts();
      return true;
    }

    // Soft Migration: Try legacy unsalted hash.
    final legacyHash = sha256.convert(utf8.encode(pin)).toString();
    if (storedHash == legacyHash) {
      // Correct PIN, now upgrade to salted hash immediately.
      await setPin(pin);
      return true;
    }

    // Increment failed attempts.
    int failed = await _getFailedAttempts() + 1;
    await _secureStorage.write(
        key: _failedAttemptsKey, value: failed.toString());

    if (failed >= maxAttempts) {
      final until =
          DateTime.now().add(const Duration(seconds: lockoutSeconds));
      await _secureStorage.write(
          key: _lockoutUntilKey,
          value: until.millisecondsSinceEpoch.toString());
    }

    return false;
  }

  /// Check if the user is currently locked out.
  Future<bool> isLockedOut() async {
    final untilStr = await _secureStorage.read(key: _lockoutUntilKey);
    if (untilStr == null) return false;
    final until =
        DateTime.fromMillisecondsSinceEpoch(int.tryParse(untilStr) ?? 0);
    if (DateTime.now().isAfter(until)) {
      await _resetFailedAttempts();
      return false;
    }
    return true;
  }

  /// Get the lockout end time (for countdown display).
  Future<DateTime?> getLockoutEnd() async {
    final untilStr = await _secureStorage.read(key: _lockoutUntilKey);
    if (untilStr == null) return null;
    final until =
        DateTime.fromMillisecondsSinceEpoch(int.tryParse(untilStr) ?? 0);
    if (DateTime.now().isAfter(until)) return null;
    return until;
  }

  /// Get the remaining failed attempts before lockout.
  Future<int> getRemainingAttempts() async {
    final failed = await _getFailedAttempts();
    return maxAttempts - failed;
  }

  // ── Biometric auth ──

  /// Check if the device supports biometric authentication.
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Whether the user has enabled biometric unlock.
  Future<bool> isBiometricEnabled() async {
    final val = await _secureStorage.read(key: _biometricEnabledKey);
    return val == 'true';
  }

  /// Enable or disable biometric unlock.
  Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
        key: _biometricEnabledKey, value: enabled.toString());
  }

  /// Attempt biometric authentication.
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your passwords',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow system PIN/Pattern fallback
        ),
      );
    } catch (_) {
      return false;
    }
  }

  // ── Private helpers ──

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    return sha256.convert(bytes).toString();
  }

  Future<int> _getFailedAttempts() async {
    final val = await _secureStorage.read(key: _failedAttemptsKey);
    return int.tryParse(val ?? '0') ?? 0;
  }

  Future<void> _resetFailedAttempts() async {
    await _secureStorage.delete(key: _failedAttemptsKey);
    await _secureStorage.delete(key: _lockoutUntilKey);
  }
}
