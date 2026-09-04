import 'package:cliper/core/utils/html_text_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HtmlTextConverter', () {
    test('extracts text from HTML-only clipboard content', () {
      const html = '<div>Hello <strong>web</strong><br>clipboard</div>';

      expect(
        HtmlTextConverter.toPlainText(html),
        'Hello web\nclipboard',
      );
    });

    test('accepts raw CF_HTML fragment markers defensively', () {
      const html = '''
Version:1.0
StartHTML:00000097
<!--StartFragment --><p>Copied &amp; pasted</p><!--EndFragment-->
''';

      expect(HtmlTextConverter.toPlainText(html), 'Copied & pasted');
    });

    test('decodes common and numeric HTML entities', () {
      const html = '<pre>&lt;tag&gt; &#x1F680; &#39;ok&#39;</pre>';

      expect(HtmlTextConverter.toPlainText(html), "<tag> 🚀 'ok'");
    });

    test('drops script and style content', () {
      const html =
          '<style>.hidden { display: none; }</style><div>visible</div><script>alert("hidden")</script>';

      expect(HtmlTextConverter.toPlainText(html), 'visible');
    });

    test('preserves significant leading and trailing whitespace', () {
      const html = '<pre>  indented  </pre>';

      expect(HtmlTextConverter.toPlainText(html), '  indented  ');
    });

    test('preserves whitespace-only HTML content', () {
      const html = '<span>&nbsp;</span>';

      expect(HtmlTextConverter.toPlainText(html), ' ');
    });

    test('handles greater-than signs inside quoted attributes', () {
      const html = '<span title="1 > 0">ok</span>';

      expect(HtmlTextConverter.toPlainText(html), 'ok');
    });

    test('adds one semantic break between adjacent block elements', () {
      const html = '<div>first</div>\n  <div>second</div>';

      expect(HtmlTextConverter.toPlainText(html), 'first\nsecond');
    });
  });
}
