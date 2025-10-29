// Shutterbook — AuthModel
// A small ChangeNotifier-based model that wraps auth services and
// persistable auth settings (password set, biometric enabled, unlocked
// state). Used to gate access to the app during startup and settings.
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _hasPassword = false;
  bool _unlocked = false;
  bool _biometricEnabled = false;

  bool get hasPassword => _hasPassword;
  bool get isUnlocked => _unlocked;
  bool get biometricEnabled => _biometricEnabled;

  /// Helper to check whether device has biometric capability and enrolled biometrics
  Future<bool> isBiometricAvailable() async {
    return await _authService.isBiometricAvailable();
  }

  Future<void> loadSettings() async {
    _hasPassword = await _authService.hasPassword();
    _biometricEnabled = await _authService.getBiometricStatus();
    notifyListeners();
  }

  Future<void> setPassword(String password) async {
    await _authService.savePassword(password);
    _hasPassword = true;
    // when password is set during setup, consider the session unlocked
    _unlocked = true;
    notifyListeners();
  }

  Future<void> changePassword(String newPassword) async {
    await _authService.savePassword(newPassword);
    notifyListeners();
  }

  Future<void> removePassword() async {
    await _authService.clearPassword();
    _hasPassword = false;
    _biometricEnabled = false;
    _unlocked = false;
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    await _authService.setBiometricStatus(value);
    _biometricEnabled = value;
    notifyListeners();
  }

  Future<bool> authenticate() async {
    return await _authService.authenticate();
  }

  /// Attempt biometric unlock and set unlocked state on success
  Future<bool> unlockWithBiometrics() async {
    final ok = await authenticate();
    if (ok) {
      _unlocked = true;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> isFirstLaunch() async {
    return await _authService.isFirstLaunch();
  }

  Future<bool> verifyPassword(String input) async {
    final ok = await _authService.verifyPassword(input);
    if (ok) {
      _unlocked = true;
      notifyListeners();
    }
    return ok;
  }
}
