import 'dart:convert';

import '../../domain/enums/clipboard_item_type.dart';

class ContentTypeDetector {
  const ContentTypeDetector._();

  static ClipboardItemType detect(String text) {
    if (text.isEmpty) return ClipboardItemType.text;

    if (_isJson(text)) return ClipboardItemType.json;
    if (_isUrl(text)) return ClipboardItemType.url;

    return ClipboardItemType.text;
  }

  static bool _isJson(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    final first = trimmed.codeUnitAt(0);
    if (first != 0x7B && first != 0x5B) return false;

    try {
      final parsed = json.decode(trimmed);
      return parsed is Map || parsed is List;
    } catch (_) {
      return false;
    }
  }

  static final _urlPattern = RegExp(
    r'^https?://[^\s/$.?#].[^\s]*$',
    caseSensitive: false,
  );

  static bool _isUrl(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    return _urlPattern.hasMatch(trimmed);
  }
}
