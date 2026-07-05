import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final _auth = LocalAuthentication();

  Future<bool> get isAvailable async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  Future<List<BiometricType>> get availableTypes async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  Future<bool> get hasBiometricEnrolled async {
    final types = await availableTypes;
    return types.isNotEmpty;
  }

  Future<String> get biometricLabel async {
    final types = await availableTypes;
    if (types.contains(BiometricType.face)) return 'Face ID';
    if (types.contains(BiometricType.fingerprint)) return 'Fingerprint';
    if (types.contains(BiometricType.iris)) return 'Iris';
    return 'Biometric';
  }

  Future<bool> authenticate({String reason = 'Unlock PayVerify'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('[Biometric] Error: ${e.code} ${e.message}');
      return false;
    }
  }

  Future<void> stopAuth() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {}
  }
}

final biometricService = BiometricService();
