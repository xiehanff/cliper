class HtmlTextConverter {
  const HtmlTextConverter._();

  static const _blockTags = <String>{
    'p',
    'div',
    'li',
    'tr',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'pre',
    'blockquote',
  };
  static final RegExp _numericEntityPattern = RegExp(
    r'&#(x[0-9a-f]+|[0-9]+);',
    caseSensitive: false,
  );
  static final RegExp _namedEntityPattern = RegExp(
    r'&(nbsp|lt|gt|quot|apos|amp);',
    caseSensitive: false,
  );
  static final RegExp _startFragmentPattern = RegExp(
    r'<!--\s*StartFragment\s*-->',
    caseSensitive: false,
  );
  static final RegExp _endFragmentPattern = RegExp(
    r'<!--\s*EndFragment\s*-->',
    caseSensitive: false,
  );

  static String toPlainText(String html) {
    if (html.isEmpty) return '';

    final fragment = _extractFragment(html);
    final output = _TextBuilder();
    var index = 0;
    var pendingBlockBreak = false;
    String? suppressedTag;

    while (index < fragment.length) {
      if (fragment.startsWith('<!--', index)) {
        final commentEnd = fragment.indexOf('-->', index + 4);
        if (commentEnd == -1) break;
        index = commentEnd + 3;
        continue;
      }

      if (fragment.codeUnitAt(index) == 0x3C) {
        final tagEnd = _findTagEnd(fragment, index + 1);
        if (tagEnd == -1) {
          if (suppressedTag == null) {
            if (pendingBlockBreak) {
              output.writeLineBreak();
              pendingBlockBreak = false;
            }
            output.write('<');
          }
          index++;
          continue;
        }

        final tag = _parseTag(fragment.substring(index + 1, tagEnd));
        if (tag != null) {
          if (suppressedTag != null) {
            if (tag.isClosing && tag.name == suppressedTag) {
              suppressedTag = null;
            }
          } else if (!tag.isClosing &&
              (tag.name == 'script' || tag.name == 'style')) {
            suppressedTag = tag.name;
          } else if (tag.name == 'br') {
            if (pendingBlockBreak) pendingBlockBreak = false;
            output.writeLineBreak();
          } else if (tag.isClosing && _blockTags.contains(tag.name)) {
            pendingBlockBreak = true;
          }
        }

        index = tagEnd + 1;
        continue;
      }

      final nextTag = fragment.indexOf('<', index);
      final textEnd = nextTag == -1 ? fragment.length : nextTag;
      final text = fragment.substring(index, textEnd);
      if (suppressedTag == null && text.isNotEmpty) {
        // Formatting whitespace between adjacent block elements belongs to the
        // HTML wrapper, not the copied text. Keep the pending semantic break
        // instead of turning it into an extra blank line.
        if (pendingBlockBreak && text.trim().isEmpty) {
          index = textEnd;
          continue;
        }
        if (pendingBlockBreak) {
          output.writeLineBreak();
          pendingBlockBreak = false;
        }
        output.write(text);
      }
      index = textEnd;
    }

    return _decodeEntities(output.toString())
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
  }

  static String _extractFragment(String html) {
    final start = _startFragmentPattern.firstMatch(html);
    if (start == null) return html;

    final end = _endFragmentPattern.firstMatch(html, start.end);
    if (end == null || end.start < start.end) return html;
    return html.substring(start.end, end.start);
  }

  static int _findTagEnd(String html, int start) {
    int? quote;
    for (var i = start; i < html.length; i++) {
      final codeUnit = html.codeUnitAt(i);
      if (quote != null) {
        if (codeUnit == quote) quote = null;
        continue;
      }
      if (codeUnit == 0x22 || codeUnit == 0x27) {
        quote = codeUnit;
      } else if (codeUnit == 0x3E) {
        return i;
      }
    }
    return -1;
  }

  static _HtmlTag? _parseTag(String rawTag) {
    var value = rawTag.trimLeft();
    if (value.isEmpty || value.startsWith('!') || value.startsWith('?')) {
      return null;
    }

    var isClosing = false;
    if (value.startsWith('/')) {
      isClosing = true;
      value = value.substring(1).trimLeft();
    }
    if (value.isEmpty) return null;

    var end = 0;
    while (end < value.length) {
      final codeUnit = value.codeUnitAt(end);
      final isNameCharacter =
          (codeUnit >= 0x30 && codeUnit <= 0x39) ||
              (codeUnit >= 0x41 && codeUnit <= 0x5A) ||
              (codeUnit >= 0x61 && codeUnit <= 0x7A) ||
              codeUnit == 0x2D ||
              codeUnit == 0x3A;
      if (!isNameCharacter) break;
      end++;
    }
    if (end == 0) return null;

    return _HtmlTag(value.substring(0, end).toLowerCase(), isClosing);
  }

  static String _decodeEntities(String value) {
    var decoded = value.replaceAllMapped(_numericEntityPattern, (match) {
      final entity = match.group(1);
      if (entity == null) return match.group(0) ?? '';

      final isHex = entity.startsWith('x') || entity.startsWith('X');
      final number = int.tryParse(
        isHex ? entity.substring(1) : entity,
        radix: isHex ? 16 : 10,
      );
      if (number == null ||
          number < 0 ||
          number > 0x10FFFF ||
          (number >= 0xD800 && number <= 0xDFFF)) {
        return match.group(0) ?? '';
      }
      return String.fromCharCode(number);
    });

    const namedEntities = <String, String>{
      'nbsp': ' ',
      'lt': '<',
      'gt': '>',
      'quot': '"',
      'apos': "'",
      'amp': '&',
    };
    decoded = decoded.replaceAllMapped(_namedEntityPattern, (match) {
      final name = match.group(1)?.toLowerCase();
      return namedEntities[name] ?? match.group(0) ?? '';
    });
    return decoded;
  }
}

class _HtmlTag {
  final String name;
  final bool isClosing;

  const _HtmlTag(this.name, this.isClosing);
}

class _TextBuilder {
  final StringBuffer _buffer = StringBuffer();
  bool _isEmpty = true;
  bool _endsWithLineBreak = false;

  void write(String value) {
    if (value.isEmpty) return;
    _buffer.write(value);
    _isEmpty = false;
    _endsWithLineBreak = value.endsWith('\n') || value.endsWith('\r');
  }

  void writeLineBreak() {
    if (_isEmpty || _endsWithLineBreak) return;
    _buffer.write('\n');
    _endsWithLineBreak = true;
  }

  @override
  String toString() => _buffer.toString();
}
