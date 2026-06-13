class AppConstants {
  AppConstants._();

  static const String appName = 'Cliper';
  static const String storeFileName = 'clipboard-store.json';

  static const String defaultTheme = 'dark';
  static const String defaultLanguage = 'zh';
  static const String defaultShortcut = 'CommandOrControl+\\';
  static const bool defaultAutoLaunch = false;

  static const int realtimeHistoryLimit = 50;

  static const List<String> groupColors = [
    '#FF6B6B',
    '#4ECDC4',
    '#FFD93D',
    '#6BCF7F',
    '#A78BFA',
    '#3B82F6',
    '#9CA3AF',
  ];

  static const List<String> supportedThemes = ['dark', 'light'];
  static const List<String> supportedLanguages = ['zh', 'en'];
}
