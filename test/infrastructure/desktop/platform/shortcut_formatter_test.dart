import 'package:cliper/infrastructure/desktop/platform/shortcut_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShortcutFormatter', () {
    test('normalizes modifier aliases', () {
      expect(ShortcutFormatter.normalize('Ctrl+A'), 'control+a');
      expect(ShortcutFormatter.normalize('Alt+Shift+X'), 'alt+shift+x');
      expect(ShortcutFormatter.normalize('Meta+Enter'), 'meta+enter');
      expect(ShortcutFormatter.normalize('Cmd+B'), 'meta+b');
    });

    test('normalizes CommandOrControl based on platform', () {
      final normalized = ShortcutFormatter.normalize('CommandOrControl+\\');
      expect(
        normalized == 'control+\\' || normalized == 'meta+\\',
        isTrue,
        reason:
            'CommandOrControl should map to control on Windows/Linux and meta on macOS',
      );
    });

    test('parse splits modifiers and key', () {
      final result = ShortcutFormatter.parse('control+shift+a');
      expect(result.modifiers, ['control', 'shift']);
      expect(result.key, 'a');
    });

    test('parse handles single key', () {
      final result = ShortcutFormatter.parse('f1');
      expect(result.modifiers, isEmpty);
      expect(result.key, 'f1');
    });
  });
}
