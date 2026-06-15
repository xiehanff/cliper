import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../../../core/utils/app_logger.dart';
import '../../../domain/services/hotkey_service.dart';
import '../platform/shortcut_formatter.dart';
import 'physical_key_map.dart';

class HotkeyManagerService implements HotkeyService {
  final void Function() _onTriggered;
  final AppLogger _logger;
  HotKey? _currentHotKey;

  HotkeyManagerService({
    required void Function() onTriggered,
    required AppLogger logger,
  })  : _onTriggered = onTriggered,
        _logger = logger;

  @override
  Future<void> register(String shortcut) async {
    try {
      await hotKeyManager.unregisterAll();
    } catch (e, stack) {
      _logger.warning('Failed to clear existing hotkeys before register');
      _logger.error(
        'Failed to clear existing hotkeys before register',
        error: e,
        stackTrace: stack,
      );
    }
    _currentHotKey = null;

    final hotKey = _parseShortcut(shortcut);
    if (hotKey == null) {
      _logger.warning('Unable to parse shortcut: $shortcut');
      return;
    }

    try {
      await hotKeyManager.register(
        hotKey,
        keyDownHandler: (_) => _onTriggered(),
      );
      _currentHotKey = hotKey;
      _logger.info('Registered hotkey: $shortcut');
    } catch (e, stack) {
      _logger.error('Failed to register hotkey: $shortcut',
          error: e, stackTrace: stack);
    }
  }

  @override
  Future<void> unregister() async {
    final hotKey = _currentHotKey;
    if (hotKey == null) return;

    try {
      await hotKeyManager.unregister(hotKey);
      _logger.info('Unregistered hotkey');
    } catch (e, stack) {
      _logger.error('Failed to unregister hotkey', error: e, stackTrace: stack);
    } finally {
      _currentHotKey = null;
    }
  }

  HotKey? _parseShortcut(String shortcut) {
    final normalized = ShortcutFormatter.normalize(shortcut);
    final (:modifiers, :key) = ShortcutFormatter.parse(normalized);

    final physicalKey = _parseKey(key);
    if (physicalKey == null) return null;

    final hotKeyModifiers =
        modifiers.map(_parseModifier).whereType<HotKeyModifier>().toList();

    return HotKey(
      key: physicalKey,
      modifiers: hotKeyModifiers,
      scope: HotKeyScope.system,
    );
  }

  PhysicalKeyboardKey? _parseKey(String key) {
    return physicalKeyMap[key.toLowerCase()];
  }

  HotKeyModifier? _parseModifier(String modifier) {
    return switch (modifier) {
      'control' => HotKeyModifier.control,
      'meta' => HotKeyModifier.meta,
      'alt' => HotKeyModifier.alt,
      'shift' => HotKeyModifier.shift,
      _ => null,
    };
  }
}
