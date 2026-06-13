import 'package:cliper/domain/entities/app_settings.dart';
import 'package:cliper/domain/entities/clipboard_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClipboardStore', () {
    test('default store has empty realtime and groups with default settings',
        () {
      const store = ClipboardStore();

      expect(store.realtime, isEmpty);
      expect(store.groups, isEmpty);
      expect(store.settings.theme, 'dark');
      expect(store.settings.language, 'zh');
      expect(store.settings.shortcut, r'CommandOrControl+\');
      expect(store.settings.autoLaunch, false);
    });

    test('serializes and deserializes round trip', () {
      const store = ClipboardStore();
      final json = store.toJson();
      final restored = ClipboardStore.fromJson(json);

      expect(restored.realtime, isEmpty);
      expect(restored.groups, isEmpty);
      expect(restored.settings.theme, store.settings.theme);
      expect(restored.settings.language, store.settings.language);
      expect(restored.settings.shortcut, store.settings.shortcut);
      expect(restored.settings.autoLaunch, store.settings.autoLaunch);
    });
  });

  group('AppSettings', () {
    test('default values match spec', () {
      const settings = AppSettings();

      expect(settings.theme, 'dark');
      expect(settings.language, 'zh');
      expect(settings.shortcut, r'CommandOrControl+\');
      expect(settings.autoLaunch, false);
    });

    test('empty shortcut falls back to default', () {
      final settings = AppSettings.fromJson(const {'shortcut': ''});

      expect(settings.shortcut, r'CommandOrControl+\');
    });

    test('missing fields merge defaults', () {
      final settings = AppSettings.fromJson(const {'theme': 'light'});

      expect(settings.theme, 'light');
      expect(settings.language, 'zh');
      expect(settings.shortcut, r'CommandOrControl+\');
      expect(settings.autoLaunch, false);
    });
  });
}
