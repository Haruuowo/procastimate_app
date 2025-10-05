import 'package:flutter/material.dart';

class ThemeService {
  ThemeService._internal();

  static final ThemeService instance = ThemeService._internal();

  // Expose a ValueNotifier so UI can listen and rebuild
  final ValueNotifier<ThemeMode> notifier = ValueNotifier(ThemeMode.light);

  ThemeMode get themeMode => notifier.value;

  void setThemeMode(ThemeMode mode) => notifier.value = mode;

  void toggle() {
    notifier.value =
        notifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}