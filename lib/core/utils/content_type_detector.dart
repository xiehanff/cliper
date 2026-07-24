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

    // Fast path: standard JSON
    try {
      final parsed = json.decode(trimmed);
      return parsed is Map || parsed is List;
    } catch (_) {
      // Fall through — try stripping JS-style comments
    }

    // Second pass: strip // and /* */ comments before parsing
    try {
      final cleaned = _stripJsonComments(trimmed);
      if (cleaned == trimmed) return false;
      final parsed = json.decode(cleaned);
      return parsed is Map || parsed is List;
    } catch (_) {
      return false;
    }
  }

  /// Removes JavaScript-style single-line (//) and multi-line (/* */) comments,
  /// respecting string literals so that "https://" is not stripped.
  static String _stripJsonComments(String text) {
    // Block comments first
    var result = text.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');

    final lines = result.split('\n');
    final cleaned = <String>[];
    for (final line in lines) {
      bool inString = false;
      bool escape = false;
      int? slashPos;

      for (int i = 0; i < line.length; i++) {
        final ch = line[i];
        if (escape) {
          escape = false;
          continue;
        }
        if (ch == '\\') {
          escape = true;
          continue;
        }
        if (ch == '"') {
          inString = !inString;
          continue;
        }
        if (!inString &&
            ch == '/' &&
            i + 1 < line.length &&
            line[i + 1] == '/') {
          slashPos = i;
          break;
        }
      }

      cleaned.add(slashPos != null ? line.substring(0, slashPos) : line);
    }

    return cleaned.join('\n');
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
