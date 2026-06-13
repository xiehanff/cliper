import 'dart:convert';

import 'package:cliper/domain/entities/clipboard_item.dart';
import 'package:cliper/domain/entities/clipboard_store.dart';
import 'package:cliper/domain/enums/clipboard_item_type.dart';
import 'package:cliper/infrastructure/models/store_serializer.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('StoreSerializer', () {
    late FakeAppLogger logger;
    late StoreSerializer serializer;

    setUp(() {
      logger = FakeAppLogger();
      serializer = StoreSerializer(logger: logger);
    });

    test('decodes legacy array format as realtime', () {
      final raw = jsonEncode([
        {
          'id': 'a1',
          'type': 'text',
          'text': 'hello',
          'image': '',
          'files': <String>[],
          'timestamp': 1000,
        },
      ]);

      final store = serializer.decode(raw);

      expect(store.realtime.length, 1);
      expect(store.realtime.first.text, 'hello');
      expect(store.groups, isEmpty);
      expect(store.settings.theme, 'dark');
      expect(store.settings.language, 'zh');
    });

    test('decodes full object format', () {
      final raw = jsonEncode({
        'realtime': [
          {
            'id': 'a1',
            'type': 'text',
            'text': 'hello',
            'image': '',
            'files': <String>[],
            'timestamp': 1000,
          },
        ],
        'groups': [
          {
            'id': 'g1',
            'name': 'Work',
            'color': '#FF6B6B',
            'items': <Map<String, dynamic>>[],
          },
        ],
        'settings': {'theme': 'light', 'language': 'en'},
      });

      final store = serializer.decode(raw);

      expect(store.realtime.length, 1);
      expect(store.groups.length, 1);
      expect(store.groups.first.name, 'Work');
      expect(store.settings.theme, 'light');
      expect(store.settings.language, 'en');
    });

    test('returns default store when JSON is corrupted', () {
      final store = serializer.decode('not valid json');

      expect(store.realtime, isEmpty);
      expect(store.groups, isEmpty);
      expect(store.settings.theme, 'dark');
      expect(logger.logs.any((l) => l.startsWith('ERROR')), isTrue);
    });

    test('empty shortcut in loaded settings falls back to default', () {
      final raw = jsonEncode({
        'settings': {'shortcut': ''},
      });

      final store = serializer.decode(raw);

      expect(store.settings.shortcut, r'CommandOrControl+\');
    });

    test('encode produces indented JSON', () {
      const item = ClipboardItem(
        id: 'a1',
        type: ClipboardItemType.text,
        text: 'hello',
        timestamp: 1000,
      );
      final store = const ClipboardStore().copyWith(realtime: [item]);

      final raw = serializer.encode(store);

      expect(raw, contains('"realtime"'));
      expect(raw, contains('"hello"'));
      expect(raw.contains('\n'), isTrue);
    });
  });
}
