import 'dart:io';

import 'package:flutter/services.dart';

import '../../core/utils/app_logger.dart';
import '../../core/utils/shortcut_label.dart';
import '../../domain/entities/clipboard_store.dart';
import '../../domain/services/hotkey_service.dart';
import '../../domain/services/launch_at_startup_service.dart';

/// Handles shortcut recording and settings (theme, language, auto-launch).
class SettingsHandler {
  final HotkeyService? _hotkeyService;
  final LaunchAtStartupService? _launchService;
  final AppLogger? _logger;

  bool shortcutRecording = false;

  SettingsHandler({
    HotkeyService? hotkeyService,
    LaunchAtStartupService? launchService,
    AppLogger? logger,
  })  : _hotkeyService = hotkeyService,
        _launchService = launchService,
        _logger = logger;

  bool get isMacOS => Platform.isMacOS;

  ClipboardStore switchTheme(ClipboardStore store, String theme) {
    return store.copyWith(
      settings: store.settings.copyWith(theme: theme),
    );
  }

  ClipboardStore switchLanguage(ClipboardStore store, String language) {
    return store.copyWith(
      settings: store.settings.copyWith(language: language),
    );
  }

  ClipboardStore setShortcutStore(ClipboardStore store, String shortcut) {
    return store.copyWith(
      settings: store.settings.copyWith(shortcut: shortcut),
    );
  }

  Future<void> applyShortcutHotkey(String shortcut) async {
    try {
      await _hotkeyService?.unregister();
      await _hotkeyService?.register(shortcut);
    } catch (e, stack) {
      _logger?.error('Failed to update hotkey', error: e, stackTrace: stack);
    }
  }

  ClipboardStore setAutoLaunchStore(ClipboardStore store, bool enabled) {
    return store.copyWith(
      settings: store.settings.copyWith(autoLaunch: enabled),
    );
  }

  Future<void> applyAutoLaunch(bool enabled) async {
    try {
      await _launchService?.setEnabled(enabled);
    } catch (e, stack) {
      _logger?.error('Failed to set auto launch', error: e, stackTrace: stack);
    }
  }

  void handleShortcutRecordingKeyEvent(KeyEvent event,
      void Function(String) onShortcutSet) {
    if (!shortcutRecording || event is! KeyDownEvent) return;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      shortcutRecording = false;
      return;
    }

    if (isOnlyModifier(key)) return;

    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final hasModifier = pressed.any(
      (k) =>
          k == LogicalKeyboardKey.controlLeft ||
          k == LogicalKeyboardKey.controlRight ||
          k == LogicalKeyboardKey.metaLeft ||
          k == LogicalKeyboardKey.metaRight ||
          k == LogicalKeyboardKey.altLeft ||
          k == LogicalKeyboardKey.altRight ||
          k == LogicalKeyboardKey.shiftLeft ||
          k == LogicalKeyboardKey.shiftRight,
    );
    if (!hasModifier) return;

    final shortcut = formatShortcut(pressed, key);
    onShortcutSet(shortcut);
    shortcutRecording = false;
  }
}
