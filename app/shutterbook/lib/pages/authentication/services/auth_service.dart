// Shutterbook — AuthService
// Thin wrapper around local_auth and SharedPreferences to store a simple
// password lock and biometric preference. Keep platform-specific logic
// contained here so the rest of the app uses the high-level AuthModel.
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _passwordKey = 'app_password';
  static const _passwordEnabledKey = 'password_enabled';
  static const _biometricsEnabledKey = 'biometrics_enabled';
  static const _firstLaunchKey = 'first_launch';

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Save a password and enable password lock
  Future<void> savePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_passwordKey, password);
    await prefs.setBool(_passwordEnabledKey, true);
  }

  /// Remove stored password and disable password lock
  Future<void> clearPassword() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_passwordKey);
    await prefs.setBool(_passwordEnabledKey, false);
  }

  /// Returns true if a password is currently saved (and enabled)
  Future<bool> hasPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_passwordEnabledKey) ?? false;
    if (!enabled) return false;
    final pw = prefs.getString(_passwordKey);
    return pw != null && pw.isNotEmpty;
  }

  /// Biometric enabled flag (default true)
  Future<bool> getBiometricStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricsEnabledKey) ?? true;
  }

  Future<void> setBiometricStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricsEnabledKey, value);
  }

  /// Return stored password
  Future<String?> getStoredPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_passwordKey);
  }

  /// Verify a password
  Future<bool> verifyPassword(String input) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_passwordKey);
    if (stored == null) return false;
    return stored == input;
  }

  /// Attempt biometric authentication
  Future<bool> authenticate() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!isSupported || !canCheck) {
        if (kDebugMode) debugPrint('AuthService.authenticate: device not supported or cannot check biometrics (isSupported=$isSupported, canCheck=$canCheck)');
        return false;
      }

      final result = await _localAuth.authenticate(
        localizedReason: 'Authenticate to continue',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (result) {
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('AuthService.authenticate exception: $e');
      return false;
    }
  }

  /// Check whether biometric authentication is available and enrolled on device
  Future<bool> isBiometricAvailable() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!isSupported || !canCheck) return false;
      final available = await _localAuth.getAvailableBiometrics();
      final ok = available.isNotEmpty;
      if (!ok) {
        if (kDebugMode) debugPrint('AuthService.isBiometricAvailable: no biometrics available, list: $available');
      }
      return ok;
    } catch (e) {
      if (kDebugMode) debugPrint('AuthService.isBiometricAvailable exception: $e');
      return false;
    }
  }

  /// Check if this is first launch ever
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final firstLaunch = prefs.getBool(_firstLaunchKey) ?? true;
    if (firstLaunch) {
      await prefs.setBool(_firstLaunchKey, false);
    }
    return firstLaunch;
  }
}
