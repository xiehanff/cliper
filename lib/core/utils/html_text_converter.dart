class HtmlTextConverter {
  const HtmlTextConverter._();

  static final RegExp _scriptPattern = RegExp(
    r'<script\b[^>]*>.*?</script\s*>',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _stylePattern = RegExp(
    r'<style\b[^>]*>.*?</style\s*>',
    caseSensitive: false,
    dotAll: true,
  );
  static final RegExp _lineBreakPattern = RegExp(
    r'<br\s*/?>',
    caseSensitive: false,
  );
  static final RegExp _blockEndPattern = RegExp(
    r'</(?:p|div|li|tr|h[1-6]|pre|blockquote)\s*>',
    caseSensitive: false,
  );
  static final RegExp _tagPattern = RegExp(r'<[^>]+>', dotAll: true);
  static final RegExp _numericEntityPattern = RegExp(
    r'&#(x[0-9a-f]+|[0-9]+);',
    caseSensitive: false,
  );
  static final RegExp _extraBlankLinesPattern = RegExp(r'\n{3,}');

  static String toPlainText(String html) {
    if (html.isEmpty) return '';

    var value = _extractFragment(html);
    value = value.replaceAll(_scriptPattern, '');
    value = value.replaceAll(_stylePattern, '');
    value = value.replaceAll(_lineBreakPattern, '\n');
    value = value.replaceAll(_blockEndPattern, '\n');
    value = value.replaceAll(_tagPattern, '');
    value = _decodeEntities(value);
    value = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    value = value.replaceAll(_extraBlankLinesPattern, '\n\n');
    return value.trim();
  }

  static String _extractFragment(String html) {
    const startMarker = '<!--StartFragment-->';
    const endMarker = '<!--EndFragment-->';
    final start = html.indexOf(startMarker);
    final end = html.indexOf(endMarker);
    if (start == -1 || end == -1 || end <= start) return html;
    return html.substring(start + startMarker.length, end);
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
      if (number == null || number < 0 || number > 0x10FFFF) {
        return match.group(0) ?? '';
      }
      return String.fromCharCode(number);
    });

    const namedEntities = <String, String>{
      '&nbsp;': ' ',
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&apos;': "'",
    };
    for (final entry in namedEntities.entries) {
      decoded = decoded.replaceAll(entry.key, entry.value);
      decoded = decoded.replaceAll(entry.key.toUpperCase(), entry.value);
    }
    return decoded;
  }
}
