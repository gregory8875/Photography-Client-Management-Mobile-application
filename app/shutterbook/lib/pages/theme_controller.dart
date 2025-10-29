// Shutterbook — ThemeController
// Simple singleton that persists the user's light/dark preference and
// exposes a ValueNotifier used by `main.dart` to rebuild the app theme.
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  ThemeController._private();
  static final ThemeController instance = ThemeController._private();

  final ValueNotifier<bool> isDark = ValueNotifier<bool>(false);

  static const _kKey = 'use_dark_mode';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isDark.value = prefs.getBool(_kKey) ?? false;
  }

  Future<void> setDark(bool dark) async {
    isDark.value = dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kKey, dark);
  }
}
