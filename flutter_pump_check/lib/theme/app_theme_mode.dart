import 'package:flutter/material.dart';

final appThemeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

ThemeMode themeModeFromString(String? value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'system':
      return ThemeMode.system;
    case 'dark':
    default:
      return ThemeMode.dark;
  }
}

String themeModeToString(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.system:
      return 'system';
    case ThemeMode.dark:
      return 'dark';
  }
}

String themeModeLabel(String? value) {
  switch (value) {
    case 'light':
      return 'Light';
    case 'system':
      return 'System';
    case 'dark':
    default:
      return 'Dark';
  }
}
