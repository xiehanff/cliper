import 'dart:io';

final class ShortcutFormatter {
  const ShortcutFormatter._();

  static const _modifierAliases = <String, String>{
    'ctrl': 'control',
    'command': 'meta',
    'cmd': 'meta',
    'win': 'meta',
    'windows': 'meta',
    'option': 'alt',
  };

  static String normalize(String shortcut) {
    final parts = shortcut
        .split('+')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final normalized = <String>[];
    for (final part in parts) {
      var lower = part.toLowerCase();
      if (lower == 'commandorcontrol') {
        lower = Platform.isMacOS ? 'meta' : 'control';
      }
      normalized.add(_modifierAliases[lower] ?? lower);
    }
    return normalized.join('+');
  }

  static ({List<String> modifiers, String key}) parse(String shortcut) {
    final normalized = normalize(shortcut);
    final parts = normalized.split('+');
    final key = parts.last;
    final modifiers = parts.sublist(0, parts.length - 1);
    return (modifiers: modifiers, key: key);
  }
}
