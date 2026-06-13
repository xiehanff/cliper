import 'package:cliper/application/services/group_service_impl.dart';
import 'package:cliper/domain/entities/clipboard_group.dart';
import 'package:cliper/domain/entities/clipboard_item.dart';
import 'package:cliper/domain/enums/clipboard_item_type.dart';
import 'package:cliper/domain/entities/clipboard_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('GroupServiceImpl', () {
    late FakeIdGenerator idGenerator;
    late GroupServiceImpl service;
    var now = 1000;

    setUp(() {
      idGenerator = FakeIdGenerator();
      service = GroupServiceImpl(
        idGenerator: idGenerator,
        clock: () => now,
      );
    });

    ClipboardItem item(String id, String text) {
      return ClipboardItem(
        id: id,
        type: ClipboardItemType.text,
        text: text,
        timestamp: now,
      );
    }

    ClipboardStore storeWithGroupAndRealtime() {
      final realtime = [item('r1', 'realtime item')];
      final groups = [
        ClipboardGroup(
          id: 'g1',
          name: 'Group 1',
          color: '#FF6B6B',
          items: [item('g1i1', 'group 1 item')],
        ),
        ClipboardGroup(
          id: 'g2',
          name: 'Group 2',
          color: '#4ECDC4',
          items: [item('g2i1', 'group 2 item')],
        ),
      ];
      return ClipboardStore(realtime: realtime, groups: groups);
    }

    test('creates group', () {
      var store = service.createGroup(
        const ClipboardStore(),
        'New Group',
        '#FFD93D',
      );

      expect(store.groups.length, 1);
      expect(store.groups.first.name, 'New Group');
      expect(store.groups.first.color, '#FFD93D');
    });

    test('deletes group', () {
      var store = service.createGroup(
        const ClipboardStore(),
        'To Delete',
        '#FFD93D',
      );
      final id = store.groups.first.id;

      store = service.deleteGroup(store, id);

      expect(store.groups, isEmpty);
    });

    test('updates group color', () {
      var store = service.createGroup(
        const ClipboardStore(),
        'Group',
        '#FF6B6B',
      );
      final id = store.groups.first.id;

      store = service.updateGroupColor(store, id, '#6BCF7F');

      expect(store.groups.first.color, '#6BCF7F');
    });

    test('realtime to group copies item and leaves realtime intact', () {
      var store = storeWithGroupAndRealtime();
      final originalRealtime = store.realtime.toList();

      store = service.moveItem(
        store,
        sourceGroupId: null,
        targetGroupId: 'g1',
        itemId: 'r1',
      );

      expect(store.realtime.length, 1);
      expect(store.realtime.first.id, 'r1');
      expect(store.groups.firstWhere((g) => g.id == 'g1').items.length, 2);
      expect(
        store.groups.firstWhere((g) => g.id == 'g1').items.first.text,
        'realtime item',
      );
      expect(store.realtime, originalRealtime);
    });

    test('group to realtime migrates item and removes from source group', () {
      var store = storeWithGroupAndRealtime();

      store = service.moveItem(
        store,
        sourceGroupId: 'g1',
        targetGroupId: null,
        itemId: 'g1i1',
      );

      expect(store.groups.firstWhere((g) => g.id == 'g1').items, isEmpty);
      expect(store.realtime.first.text, 'group 1 item');
      expect(store.realtime.length, 2);
    });

    test('group to group migrates item and removes from source group', () {
      var store = storeWithGroupAndRealtime();

      store = service.moveItem(
        store,
        sourceGroupId: 'g1',
        targetGroupId: 'g2',
        itemId: 'g1i1',
      );

      expect(store.groups.firstWhere((g) => g.id == 'g1').items, isEmpty);
      expect(
        store.groups.firstWhere((g) => g.id == 'g2').items.length,
        2,
      );
      expect(
        store.groups.firstWhere((g) => g.id == 'g2').items.first.text,
        'group 1 item',
      );
    });

    test('delete item from group removes only that item', () {
      var store = storeWithGroupAndRealtime();

      store = service.deleteItemFromGroup(store, 'g1', 'g1i1');

      expect(store.groups.firstWhere((g) => g.id == 'g1').items, isEmpty);
      expect(store.realtime.length, 1);
    });
  });
}
