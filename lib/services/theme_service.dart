import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  ThemeService._internal();

  static final ThemeService instance = ThemeService._internal();

  final ValueNotifier<ThemeMode> notifier = ValueNotifier(ThemeMode.light);

  static const _themeKey = 'theme_mode';

  /// Initialize theme from saved preference
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeKey);

    if (saved == 'dark') {
      notifier.value = ThemeMode.dark;
    } else if (saved == 'light') {
      notifier.value = ThemeMode.light;
    } else {
      notifier.value = ThemeMode.system;
    }
  }

  ThemeMode get themeMode => notifier.value;

  /// Set and persist the theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    notifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeKey,
      mode == ThemeMode.dark
          ? 'dark'
          : mode == ThemeMode.light
              ? 'light'
              : 'system',
    );
  }

  /// Toggle between dark and light mode
  void toggle() {
    setThemeMode(
      notifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }
}