import 'package:super_clipboard/super_clipboard.dart';

import '../../../core/utils/html_text_converter.dart';

class ClipboardTextReader {
  const ClipboardTextReader._();

  static Future<String?> read(ClipboardReader reader) async {
    if (reader.canProvide(Formats.plainText)) {
      final text = await reader.readValue(Formats.plainText);
      if (text != null && text.isNotEmpty) return text;
    }

    if (reader.canProvide(Formats.htmlText)) {
      final html = await reader.readValue(Formats.htmlText);
      if (html != null && html.isNotEmpty) {
        final text = HtmlTextConverter.toPlainText(html);
        if (text.isNotEmpty) return text;
      }
    }

    return null;
  }
}
