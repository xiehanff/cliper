import 'package:cliper/domain/entities/clipboard_item.dart';
import 'package:cliper/domain/enums/clipboard_item_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_services.dart';
import '../helpers/widget_test_app.dart';

void main() {
  const transparentPngDataUrl =
      'data:image/png;base64,'
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jx7cAAAAASUVORK5CYII=';

  testWidgets('item list renders text, image and file items', (tester) async {
    final controller = createTestController();
    controller.addClipboardItem(
      const ClipboardItem(
        id: 'text-1',
        type: ClipboardItemType.text,
        text: 'Hello world',
        timestamp: 1700000000000,
      ),
    );
    controller.addClipboardItem(
      const ClipboardItem(
        id: 'image-1',
        type: ClipboardItemType.image,
        image: transparentPngDataUrl,
        timestamp: 1700000000001,
      ),
    );
    controller.addClipboardItem(
      const ClipboardItem(
        id: 'file-1',
        type: ClipboardItemType.file,
        files: ['/tmp/a.txt', '/tmp/b.txt'],
        timestamp: 1700000000002,
      ),
    );

    await tester.pumpWidget(buildTestableWidget(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Hello world'), findsOneWidget);
    expect(find.textContaining('/tmp/a.txt'), findsOneWidget);
    expect(find.text('Image'), findsOneWidget);
    expect(find.textContaining('/tmp/b.txt'), findsOneWidget);
  });
}
