import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';

@immutable
class AppSettings {
  final String theme;
  final String language;
  final String shortcut;
  final bool autoLaunch;

  const AppSettings({
    this.theme = AppConstants.defaultTheme,
    this.language = AppConstants.defaultLanguage,
    this.shortcut = AppConstants.defaultShortcut,
    this.autoLaunch = AppConstants.defaultAutoLaunch,
  });

  AppSettings copyWith({
    String? theme,
    String? language,
    String? shortcut,
    bool? autoLaunch,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      shortcut: shortcut ?? this.shortcut,
      autoLaunch: autoLaunch ?? this.autoLaunch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'language': language,
      'shortcut': shortcut,
      'autoLaunch': autoLaunch,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final rawShortcut =
        json['shortcut'] as String? ?? AppConstants.defaultShortcut;
    return AppSettings(
      theme: json['theme'] as String? ?? AppConstants.defaultTheme,
      language: json['language'] as String? ?? AppConstants.defaultLanguage,
      shortcut:
          rawShortcut.isEmpty ? AppConstants.defaultShortcut : rawShortcut,
      autoLaunch: json['autoLaunch'] as bool? ?? AppConstants.defaultAutoLaunch,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          runtimeType == other.runtimeType &&
          theme == other.theme &&
          language == other.language &&
          shortcut == other.shortcut &&
          autoLaunch == other.autoLaunch;

  @override
  int get hashCode => Object.hash(theme, language, shortcut, autoLaunch);

  @override
  String toString() {
    return 'AppSettings(theme: $theme, language: $language, shortcut: $shortcut, autoLaunch: $autoLaunch)';
  }
}
