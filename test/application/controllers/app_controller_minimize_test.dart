import 'package:cliper/domain/entities/clipboard_item.dart';
import 'package:cliper/domain/enums/clipboard_item_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../presentation/helpers/fake_services.dart';

ClipboardItem _textItem() => const ClipboardItem(
      id: 'item-1',
      type: ClipboardItemType.text,
      text: 'hello',
      timestamp: 1700000000000,
    );

void main() {
  test('activating an item minimizes the window when hide is disabled', () async {
    final window = FakeWindowController()
      ..hideAfterActivation = false
      ..minimizeAfterActivation = true;
    final controller = createTestController(windowController: window);

    controller.addClipboardItem(_textItem());
    final items = controller.currentItems;
    expect(items, isNotEmpty);

    await controller.activateItem(items.first.id);

    expect(window.minimizeCount, 1);
    expect(window.hideCount, 0);
  });

  test('activating an item hides the window by default', () async {
    final window = FakeWindowController();
    final controller = createTestController(windowController: window);

    controller.addClipboardItem(_textItem());
    final items = controller.currentItems;
    expect(items, isNotEmpty);

    await controller.activateItem(items.first.id);

    expect(window.hideCount, 1);
    expect(window.minimizeCount, 0);
  });
}
