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

    test('uses CF_HTML fragment markers when present', () {
      const html = '''
Version:1.0
StartHTML:00000097
<!--StartFragment--><p>Copied &amp; pasted</p><!--EndFragment-->
''';

      expect(HtmlTextConverter.toPlainText(html), 'Copied & pasted');
    });

    test('decodes common and numeric HTML entities', () {
      const html = '<pre>&lt;tag&gt; &#x1F680; &#39;ok&#39;&nbsp;</pre>';

      expect(HtmlTextConverter.toPlainText(html), "<tag> 🚀 'ok'");
    });

    test('drops script and style content', () {
      const html = '''
<style>.hidden { display: none; }</style>
<div>visible</div>
<script>alert('hidden')</script>
''';

      expect(HtmlTextConverter.toPlainText(html), 'visible');
    });
  });
}
