import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth/pin_auth_service.dart';
import '../services/auth/biometric_service.dart';

final appLockProvider = StateProvider<bool>((ref) => true);

final pinSetupProvider = FutureProvider<bool>((ref) async {
  return pinAuthService.isPinSetup;
});

final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  final available = await biometricService.isAvailable;
  final enrolled = await biometricService.hasBiometricEnrolled;
  return available && enrolled;
});

final biometricEnabledProvider = FutureProvider<bool>((ref) async {
  return pinAuthService.isBiometricEnabled;
});

final biometricLabelProvider = FutureProvider<String>((ref) async {
  return biometricService.biometricLabel;
});
