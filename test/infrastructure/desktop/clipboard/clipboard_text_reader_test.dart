import 'package:cliper/infrastructure/desktop/clipboard/clipboard_text_reader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_clipboard/super_clipboard.dart';

void main() {
  group('ClipboardTextReader', () {
    test('prefers plain text and preserves its whitespace', () async {
      final reader = _FakeClipboardReader(
        plainText: '  plain  ',
        htmlText: '<b>html</b>',
      );

      expect(await ClipboardTextReader.read(reader), '  plain  ');
    });

    test('falls back to HTML when plain text is unavailable', () async {
      final reader = _FakeClipboardReader(
        htmlText: '<span title="1 > 0">  web&nbsp;</span>',
      );

      expect(await ClipboardTextReader.read(reader), '  web ');
    });

    test('keeps whitespace-only HTML clipboard content', () async {
      final reader = _FakeClipboardReader(
        htmlText: '<span>&nbsp;</span>',
      );

      expect(await ClipboardTextReader.read(reader), ' ');
    });

    test('falls back to HTML when provided plain text is empty', () async {
      final reader = _FakeClipboardReader(
        plainText: '',
        htmlText: '<div>fallback</div>',
      );

      expect(await ClipboardTextReader.read(reader), 'fallback');
    });
  });
}

class _FakeClipboardReader extends ClipboardReader {
  _FakeClipboardReader({this.plainText, this.htmlText}) : super(const []);

  final String? plainText;
  final String? htmlText;

  @override
  bool canProvide(DataFormat format) {
    if (identical(format, Formats.plainText)) return plainText != null;
    if (identical(format, Formats.htmlText)) return htmlText != null;
    return false;
  }

  @override
  Future<T?> readValue<T extends Object>(ValueFormat<T> format) async {
    Object? value;
    if (identical(format, Formats.plainText)) {
      value = plainText;
    } else if (identical(format, Formats.htmlText)) {
      value = htmlText;
    }
    return value as T?;
  }
}
