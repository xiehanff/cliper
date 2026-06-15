import 'dart:io';

import 'package:cliper/application/services/clipboard_history_service_impl.dart';
import 'package:cliper/core/constants/app_constants.dart';
import 'package:cliper/domain/entities/clipboard_item.dart';
import 'package:cliper/domain/enums/clipboard_item_type.dart';
import 'package:cliper/domain/entities/clipboard_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('ClipboardHistoryServiceImpl', () {
    late FakeIdGenerator idGenerator;
    late ClipboardHistoryServiceImpl service;
    var now = 1000;

    ClipboardItem textItem(String text, {String? id, int? timestamp}) {
      return ClipboardItem(
        id: id ?? '',
        type: ClipboardItemType.text,
        text: text,
        timestamp: timestamp ?? now,
      );
    }

    ClipboardItem imageItem(String image, {String? id, int? timestamp}) {
      return ClipboardItem(
        id: id ?? '',
        type: ClipboardItemType.image,
        image: image,
        timestamp: timestamp ?? now,
      );
    }

    ClipboardItem fileItem(List<String> files, {String? id, int? timestamp}) {
      return ClipboardItem(
        id: id ?? '',
        type: ClipboardItemType.file,
        files: files,
        timestamp: timestamp ?? now,
      );
    }

    setUp(() {
      idGenerator = FakeIdGenerator();
      service = ClipboardHistoryServiceImpl(
        idGenerator: idGenerator,
        clock: () => now,
      );
    });

    test('inserts new text item at top', () {
      var store = const ClipboardStore();

      store = service.addItem(store, textItem('first'));
      expect(store.realtime.length, 1);
      expect(store.realtime.first.text, 'first');

      store = service.addItem(store, textItem('second'));
      expect(store.realtime.length, 2);
      expect(store.realtime.first.text, 'second');
      expect(store.realtime.last.text, 'first');
    });

    test('text duplicate is not inserted', () {
      var store = service.addItem(
        const ClipboardStore(),
        textItem('duplicate'),
      );
      store = service.addItem(store, textItem('duplicate'));

      expect(store.realtime.length, 1);
    });

    test('image duplicate is not inserted', () {
      var store = service.addItem(
        const ClipboardStore(),
        imageItem('data:image/png;base64,abc'),
      );
      store = service.addItem(
        store,
        imageItem('data:image/png;base64,abc'),
      );

      expect(store.realtime.length, 1);
    });

    test('file duplicate is not inserted', () {
      var store = service.addItem(
        const ClipboardStore(),
        fileItem(['C:\\file1.txt', 'C:\\file2.txt']),
      );
      store = service.addItem(
        store,
        fileItem(['C:\\file1.txt', 'C:\\file2.txt']),
      );

      expect(store.realtime.length, 1);
    });

    test(
      'file duplicate is not inserted ignoring Windows path case',
      () {
        var store = service.addItem(
          const ClipboardStore(),
          fileItem(['C:\\Foo\\Bar.txt']),
        );
        store = service.addItem(
          store,
          fileItem(['c:\\foo\\bar.txt']),
        );

        expect(store.realtime.length, 1);
      },
      skip: !Platform.isWindows,
    );

    test('different types with same string are not duplicates', () {
      var store = service.addItem(const ClipboardStore(), textItem('abc'));
      store = service.addItem(store, imageItem('abc'));

      expect(store.realtime.length, 2);
    });

    test('realtime history is trimmed to 50 items', () {
      var store = const ClipboardStore();
      for (var i = 0; i < AppConstants.realtimeHistoryLimit + 10; i++) {
        store = service.addItem(store, textItem('item-$i'));
      }

      expect(store.realtime.length, AppConstants.realtimeHistoryLimit);
      expect(store.realtime.first.text,
          'item-${AppConstants.realtimeHistoryLimit + 9}');
      expect(store.realtime.last.text, 'item-10');
    });

    test('activating realtime item moves it to top and updates timestamp', () {
      var store = const ClipboardStore();
      store = service.addItem(
          store, textItem('first', id: 'id-1', timestamp: 1000));
      store = service.addItem(
          store, textItem('second', id: 'id-2', timestamp: 2000));

      now = 3000;
      store = service.activateItem(store, 'id-1');

      expect(store.realtime.length, 2);
      expect(store.realtime.first.id, 'id-1');
      expect(store.realtime.first.timestamp, 3000);
      expect(store.realtime.last.id, 'id-2');
    });

    test('activating top item leaves order unchanged', () {
      var store = const ClipboardStore();
      store = service.addItem(
          store, textItem('first', id: 'id-1', timestamp: 1000));
      store = service.addItem(
          store, textItem('second', id: 'id-2', timestamp: 2000));

      store = service.activateItem(store, 'id-2');

      expect(store.realtime.first.id, 'id-2');
      expect(store.realtime.last.id, 'id-1');
    });

    test('delete removes item from realtime', () {
      var store = const ClipboardStore();
      store = service.addItem(store, textItem('first'));
      final id = store.realtime.first.id;

      store = service.deleteItem(store, id);

      expect(store.realtime, isEmpty);
    });
  });
}
