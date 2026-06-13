import 'dart:io';

import 'package:flutter/services.dart';

String formatShortcut(
  Set<LogicalKeyboardKey> pressedModifiers,
  LogicalKeyboardKey key,
) {
  final parts = <String>[];

  final hasControl = pressedModifiers.any(
    (k) =>
        k == LogicalKeyboardKey.controlLeft ||
        k == LogicalKeyboardKey.controlRight,
  );
  final hasMeta = pressedModifiers.any(
    (k) =>
        k == LogicalKeyboardKey.metaLeft || k == LogicalKeyboardKey.metaRight,
  );
  final hasAlt = pressedModifiers.any(
    (k) => k == LogicalKeyboardKey.altLeft || k == LogicalKeyboardKey.altRight,
  );
  final hasShift = pressedModifiers.any(
    (k) =>
        k == LogicalKeyboardKey.shiftLeft || k == LogicalKeyboardKey.shiftRight,
  );

  if (hasControl || hasMeta) {
    parts.add('CommandOrControl');
  }
  if (hasAlt) parts.add('Alt');
  if (hasShift) parts.add('Shift');

  parts.add(_normalizeKeyLabel(key));

  return parts.join('+');
}

String _normalizeKeyLabel(LogicalKeyboardKey key) {
  final label = key.keyLabel;
  if (label.length == 1 && label.toUpperCase() != label.toLowerCase()) {
    return label.toLowerCase();
  }
  return label;
}

bool isOnlyModifier(LogicalKeyboardKey key) {
  return key == LogicalKeyboardKey.controlLeft ||
      key == LogicalKeyboardKey.controlRight ||
      key == LogicalKeyboardKey.metaLeft ||
      key == LogicalKeyboardKey.metaRight ||
      key == LogicalKeyboardKey.altLeft ||
      key == LogicalKeyboardKey.altRight ||
      key == LogicalKeyboardKey.shiftLeft ||
      key == LogicalKeyboardKey.shiftRight;
}

String platformAwareShortcutLabel(String shortcut) {
  if (Platform.isMacOS) {
    return shortcut
        .replaceAll('CommandOrControl', '⌘')
        .replaceAll('Alt', '⌥')
        .replaceAll('Shift', '⇧');
  }
  return shortcut
      .replaceAll('CommandOrControl', 'Ctrl')
      .replaceAll('Meta', 'Win');
}
