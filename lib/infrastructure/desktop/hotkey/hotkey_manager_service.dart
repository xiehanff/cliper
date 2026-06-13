import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../../../core/utils/app_logger.dart';
import '../../../domain/services/hotkey_service.dart';
import '../platform/shortcut_formatter.dart';

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
    return _physicalKeyMap[key.toLowerCase()];
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

  static final Map<String, PhysicalKeyboardKey> _physicalKeyMap = {
    // Letters
    'keya': PhysicalKeyboardKey.keyA,
    'a': PhysicalKeyboardKey.keyA,
    'keyb': PhysicalKeyboardKey.keyB,
    'b': PhysicalKeyboardKey.keyB,
    'keyc': PhysicalKeyboardKey.keyC,
    'c': PhysicalKeyboardKey.keyC,
    'keyd': PhysicalKeyboardKey.keyD,
    'd': PhysicalKeyboardKey.keyD,
    'keye': PhysicalKeyboardKey.keyE,
    'e': PhysicalKeyboardKey.keyE,
    'keyf': PhysicalKeyboardKey.keyF,
    'f': PhysicalKeyboardKey.keyF,
    'keyg': PhysicalKeyboardKey.keyG,
    'g': PhysicalKeyboardKey.keyG,
    'keyh': PhysicalKeyboardKey.keyH,
    'h': PhysicalKeyboardKey.keyH,
    'keyi': PhysicalKeyboardKey.keyI,
    'i': PhysicalKeyboardKey.keyI,
    'keyj': PhysicalKeyboardKey.keyJ,
    'j': PhysicalKeyboardKey.keyJ,
    'keyk': PhysicalKeyboardKey.keyK,
    'k': PhysicalKeyboardKey.keyK,
    'keyl': PhysicalKeyboardKey.keyL,
    'l': PhysicalKeyboardKey.keyL,
    'keym': PhysicalKeyboardKey.keyM,
    'm': PhysicalKeyboardKey.keyM,
    'keyn': PhysicalKeyboardKey.keyN,
    'n': PhysicalKeyboardKey.keyN,
    'keyo': PhysicalKeyboardKey.keyO,
    'o': PhysicalKeyboardKey.keyO,
    'keyp': PhysicalKeyboardKey.keyP,
    'p': PhysicalKeyboardKey.keyP,
    'keyq': PhysicalKeyboardKey.keyQ,
    'q': PhysicalKeyboardKey.keyQ,
    'keyr': PhysicalKeyboardKey.keyR,
    'r': PhysicalKeyboardKey.keyR,
    'keys': PhysicalKeyboardKey.keyS,
    's': PhysicalKeyboardKey.keyS,
    'keyt': PhysicalKeyboardKey.keyT,
    't': PhysicalKeyboardKey.keyT,
    'keyu': PhysicalKeyboardKey.keyU,
    'u': PhysicalKeyboardKey.keyU,
    'keyv': PhysicalKeyboardKey.keyV,
    'v': PhysicalKeyboardKey.keyV,
    'keyw': PhysicalKeyboardKey.keyW,
    'w': PhysicalKeyboardKey.keyW,
    'keyx': PhysicalKeyboardKey.keyX,
    'x': PhysicalKeyboardKey.keyX,
    'keyy': PhysicalKeyboardKey.keyY,
    'y': PhysicalKeyboardKey.keyY,
    'keyz': PhysicalKeyboardKey.keyZ,
    'z': PhysicalKeyboardKey.keyZ,
    // Digits
    'digit0': PhysicalKeyboardKey.digit0,
    '0': PhysicalKeyboardKey.digit0,
    'digit1': PhysicalKeyboardKey.digit1,
    '1': PhysicalKeyboardKey.digit1,
    'digit2': PhysicalKeyboardKey.digit2,
    '2': PhysicalKeyboardKey.digit2,
    'digit3': PhysicalKeyboardKey.digit3,
    '3': PhysicalKeyboardKey.digit3,
    'digit4': PhysicalKeyboardKey.digit4,
    '4': PhysicalKeyboardKey.digit4,
    'digit5': PhysicalKeyboardKey.digit5,
    '5': PhysicalKeyboardKey.digit5,
    'digit6': PhysicalKeyboardKey.digit6,
    '6': PhysicalKeyboardKey.digit6,
    'digit7': PhysicalKeyboardKey.digit7,
    '7': PhysicalKeyboardKey.digit7,
    'digit8': PhysicalKeyboardKey.digit8,
    '8': PhysicalKeyboardKey.digit8,
    'digit9': PhysicalKeyboardKey.digit9,
    '9': PhysicalKeyboardKey.digit9,
    // Symbols
    'backslash': PhysicalKeyboardKey.backslash,
    '\\': PhysicalKeyboardKey.backslash,
    'slash': PhysicalKeyboardKey.slash,
    '/': PhysicalKeyboardKey.slash,
    'period': PhysicalKeyboardKey.period,
    '.': PhysicalKeyboardKey.period,
    'comma': PhysicalKeyboardKey.comma,
    ',': PhysicalKeyboardKey.comma,
    'semicolon': PhysicalKeyboardKey.semicolon,
    ';': PhysicalKeyboardKey.semicolon,
    'quote': PhysicalKeyboardKey.quote,
    "'": PhysicalKeyboardKey.quote,
    '"': PhysicalKeyboardKey.quote,
    'backquote': PhysicalKeyboardKey.backquote,
    '`': PhysicalKeyboardKey.backquote,
    'bracketleft': PhysicalKeyboardKey.bracketLeft,
    '[': PhysicalKeyboardKey.bracketLeft,
    'bracketright': PhysicalKeyboardKey.bracketRight,
    ']': PhysicalKeyboardKey.bracketRight,
    'minus': PhysicalKeyboardKey.minus,
    '-': PhysicalKeyboardKey.minus,
    'equal': PhysicalKeyboardKey.equal,
    '=': PhysicalKeyboardKey.equal,
    'numpadadd': PhysicalKeyboardKey.numpadAdd,
    '+': PhysicalKeyboardKey.numpadAdd,
    'numpadmultiply': PhysicalKeyboardKey.numpadMultiply,
    '*': PhysicalKeyboardKey.numpadMultiply,
    // Function keys
    'f1': PhysicalKeyboardKey.f1,
    'f2': PhysicalKeyboardKey.f2,
    'f3': PhysicalKeyboardKey.f3,
    'f4': PhysicalKeyboardKey.f4,
    'f5': PhysicalKeyboardKey.f5,
    'f6': PhysicalKeyboardKey.f6,
    'f7': PhysicalKeyboardKey.f7,
    'f8': PhysicalKeyboardKey.f8,
    'f9': PhysicalKeyboardKey.f9,
    'f10': PhysicalKeyboardKey.f10,
    'f11': PhysicalKeyboardKey.f11,
    'f12': PhysicalKeyboardKey.f12,
    // Named keys
    'space': PhysicalKeyboardKey.space,
    ' ': PhysicalKeyboardKey.space,
    'enter': PhysicalKeyboardKey.enter,
    'return': PhysicalKeyboardKey.enter,
    'tab': PhysicalKeyboardKey.tab,
    'escape': PhysicalKeyboardKey.escape,
    'esc': PhysicalKeyboardKey.escape,
    'backspace': PhysicalKeyboardKey.backspace,
    'delete': PhysicalKeyboardKey.delete,
    'del': PhysicalKeyboardKey.delete,
    'home': PhysicalKeyboardKey.home,
    'end': PhysicalKeyboardKey.end,
    'pageup': PhysicalKeyboardKey.pageUp,
    'pagedown': PhysicalKeyboardKey.pageDown,
    'arrowup': PhysicalKeyboardKey.arrowUp,
    'up': PhysicalKeyboardKey.arrowUp,
    'arrowdown': PhysicalKeyboardKey.arrowDown,
    'down': PhysicalKeyboardKey.arrowDown,
    'arrowleft': PhysicalKeyboardKey.arrowLeft,
    'left': PhysicalKeyboardKey.arrowLeft,
    'arrowright': PhysicalKeyboardKey.arrowRight,
    'right': PhysicalKeyboardKey.arrowRight,
  };
}
