import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'biometric_service.dart';

class PinAuthService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _kPinHash = 'payverify_pin_hash';
  static const _kBiometricEnabled = 'payverify_biometric_enabled';
  static const _kFailedAttempts = 'payverify_failed_attempts';
  static const _kLockUntil = 'payverify_lock_until';
  static const _kPinSetup = 'payverify_pin_setup';
  static const _kActiveMode = 'payverify_active_unlock_mode';

  static String _hashPin(String pin) {
    const salt = 'payverify_fira_tech_2026';
    final bytes = utf8.encode(salt + pin);
    return sha256.convert(bytes).toString();
  }

  Future<bool> get isPinSetup async {
    final v = await _storage.read(key: _kPinSetup);
    return v == 'true';
  }

  Future<void> setupPin(String pin) async {
    await _storage.write(key: _kPinHash, value: _hashPin(pin));
    await _storage.write(key: _kPinSetup, value: 'true');
    await _storage.write(key: _kFailedAttempts, value: '0');
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _kPinHash);
    await _storage.delete(key: _kPinSetup);
    await _storage.delete(key: _kFailedAttempts);
    await _storage.delete(key: _kLockUntil);
    await _storage.delete(key: _kBiometricEnabled);
    await _storage.delete(key: _kActiveMode);
  }

  Future<String> getActiveMode() async {
    final stored = await _storage.read(key: _kActiveMode);
    if (stored != null) return stored;
    final bioAvail = await biometricService.isAvailable &&
        await biometricService.hasBiometricEnrolled;
    return bioAvail ? 'BIOMETRIC' : 'PIN';
  }

  Future<void> setActiveMode(String mode) async {
    await _storage.write(key: _kActiveMode, value: mode);
  }

  Future<bool> get isBiometricEnabled async {
    final v = await _storage.read(key: _kBiometricEnabled);
    return v == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _kBiometricEnabled, value: enabled.toString());
  }

  Future<bool> get isLockedOut async {
    final lockUntilStr = await _storage.read(key: _kLockUntil);
    if (lockUntilStr == null) return false;
    final lockUntil = DateTime.parse(lockUntilStr);
    return DateTime.now().isBefore(lockUntil);
  }

  Future<Duration?> get lockoutRemaining async {
    final lockUntilStr = await _storage.read(key: _kLockUntil);
    if (lockUntilStr == null) return null;
    final lockUntil = DateTime.parse(lockUntilStr);
    final remaining = lockUntil.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  Future<int> get failedAttempts async {
    final v = await _storage.read(key: _kFailedAttempts);
    return int.tryParse(v ?? '0') ?? 0;
  }

  Future<void> _recordFailedAttempt() async {
    final attempts = await failedAttempts + 1;
    await _storage.write(key: _kFailedAttempts, value: attempts.toString());

    Duration? lockDuration;
    if (attempts >= 15) {
      lockDuration = const Duration(minutes: 30);
    } else if (attempts >= 10) {
      lockDuration = const Duration(minutes: 5);
    } else if (attempts >= 5) {
      lockDuration = const Duration(seconds: 30);
    }

    if (lockDuration != null) {
      final lockUntil = DateTime.now().add(lockDuration);
      await _storage.write(key: _kLockUntil, value: lockUntil.toIso8601String());
    }
  }

  Future<void> _clearLockout() async {
    await _storage.write(key: _kFailedAttempts, value: '0');
    await _storage.delete(key: _kLockUntil);
  }

  Future<PinVerifyResult> verifyPin(String pin) async {
    if (await isLockedOut) {
      final remaining = await lockoutRemaining;
      return PinVerifyResult.lockedOut(remaining ?? Duration.zero);
    }

    final stored = await _storage.read(key: _kPinHash);
    if (stored == null) return PinVerifyResult.notSetup();

    if (_hashPin(pin) == stored) {
      await _clearLockout();
      return PinVerifyResult.success();
    } else {
      await _recordFailedAttempt();
      final attempts = await failedAttempts;
      final remaining = 5 - (attempts % 5);
      return PinVerifyResult.wrongPin(
        attemptsLeft: remaining > 0 ? remaining : 0,
      );
    }
  }

  Future<bool> changePin(String currentPin, String newPin) async {
    final result = await verifyPin(currentPin);
    if (!result.isSuccess) return false;
    await setupPin(newPin);
    return true;
  }
}

class PinVerifyResult {
  final bool isSuccess;
  final bool isLockedOut;
  final bool isNotSetup;
  final int attemptsLeft;
  final Duration lockDuration;

  const PinVerifyResult._({
    this.isSuccess = false,
    this.isLockedOut = false,
    this.isNotSetup = false,
    this.attemptsLeft = 0,
    this.lockDuration = Duration.zero,
  });

  factory PinVerifyResult.success() =>
      const PinVerifyResult._(isSuccess: true);
  factory PinVerifyResult.wrongPin({required int attemptsLeft}) =>
      PinVerifyResult._(attemptsLeft: attemptsLeft);
  factory PinVerifyResult.lockedOut(Duration duration) =>
      PinVerifyResult._(isLockedOut: true, lockDuration: duration);
  factory PinVerifyResult.notSetup() =>
      const PinVerifyResult._(isNotSetup: true);
}

final pinAuthService = PinAuthService();
