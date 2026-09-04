import 'dart:async';

import 'package:cliper/application/controllers/app_controller.dart';
import 'package:cliper/application/controllers/settings_handler.dart';
import 'package:cliper/application/services/clipboard_history_service_impl.dart';
import 'package:cliper/application/services/group_service_impl.dart';
import 'package:cliper/infrastructure/desktop/clipboard/clipboard_monitor_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_clipboard/super_clipboard.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  test('retries a missed read and records HTML-only text in history', () async {
    final repository = InMemoryStoreRepository();
    final idGenerator = FakeIdGenerator();
    final logger = FakeAppLogger();
    var now = 1000;

    final controller = AppController(
      storeRepository: repository,
      historyService: ClipboardHistoryServiceImpl(
        idGenerator: idGenerator,
        clock: () => now,
      ),
      groupService: GroupServiceImpl(
        idGenerator: idGenerator,
        clock: () => now,
      ),
      settingsHandler: SettingsHandler(),
      logger: logger,
    );
    addTearDown(controller.dispose);
    await controller.loadStore();

    final itemAdded = Completer<void>();
    controller.addListener(() {
      if (!itemAdded.isCompleted && controller.store.realtime.isNotEmpty) {
        itemAdded.complete();
      }
    });

    var readCount = 0;
    final monitor = ClipboardMonitorManager(
      appController: controller,
      logger: logger,
      idGenerator: idGenerator,
      clock: () => now,
      readRetryDelays: const [Duration.zero, Duration.zero],
      clipboardReaderProvider: () async {
        readCount++;
        if (readCount == 1) {
          return _FakeClipboardReader();
        }
        now = 2000;
        return _FakeClipboardReader(
          htmlText: '<div>hello <strong>web</strong></div>',
        );
      },
    );

    monitor.onClipboardChanged();
    await itemAdded.future.timeout(const Duration(seconds: 1));

    expect(readCount, 2);
    expect(controller.store.realtime.length, 1);
    expect(controller.store.realtime.single.text, 'hello web');
    expect(controller.store.realtime.single.timestamp, 2000);
  });
}

class _FakeClipboardReader extends ClipboardReader {
  _FakeClipboardReader({this.htmlText}) : super(const []);

  final String? htmlText;

  @override
  bool canProvide(DataFormat format) {
    if (identical(format, Formats.htmlText)) return htmlText != null;
    return false;
  }

  @override
  Future<T?> readValue<T extends Object>(ValueFormat<T> format) async {
    if (identical(format, Formats.htmlText)) {
      return htmlText as T?;
    }
    return null;
  }
}
