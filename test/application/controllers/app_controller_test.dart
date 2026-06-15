import 'package:cliper/application/controllers/app_controller.dart';
import 'package:cliper/application/controllers/settings_handler.dart';
import 'package:cliper/application/services/clipboard_history_service_impl.dart';
import 'package:cliper/application/services/group_service_impl.dart';
import 'package:cliper/core/constants/app_constants.dart';
import 'package:cliper/domain/entities/clipboard_item.dart';
import 'package:cliper/domain/enums/clipboard_item_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('AppController', () {
    late InMemoryStoreRepository repository;
    late FakeIdGenerator idGenerator;
    late AppController controller;
    var now = 1000;

    setUp(() {
      repository = InMemoryStoreRepository();
      idGenerator = FakeIdGenerator();
      controller = AppController(
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
      );
    });

    test('loadStore populates default store', () async {
      await controller.loadStore();

      expect(controller.store.realtime, isEmpty);
      expect(controller.currentTheme, 'dark');
      expect(controller.currentLanguage, 'zh');
      expect(controller.currentShortcut, r'CommandOrControl+\');
    });

    test('switchTheme updates settings and persists', () async {
      await controller.loadStore();
      controller.switchTheme('light');

      expect(controller.currentTheme, 'light');
      expect(controller.store.settings.theme, 'light');
      expect(repository.saveCount, greaterThan(0));
    });

    test('switchLanguage updates settings', () async {
      await controller.loadStore();
      controller.switchLanguage('en');

      expect(controller.currentLanguage, 'en');
    });

    test('unsupported theme or language is ignored', () async {
      await controller.loadStore();
      controller.switchTheme('neon');
      controller.switchLanguage('jp');

      expect(controller.currentTheme, 'dark');
      expect(controller.currentLanguage, 'zh');
    });

    test('createGroup and deleteGroup update state', () async {
      await controller.loadStore();
      controller.createGroup('Work', AppConstants.groupColors.first);

      expect(controller.groups.length, 1);
      final id = controller.groups.first.id;

      controller.selectGroup(id);
      expect(controller.currentGroupId, id);

      controller.deleteGroup(id);
      expect(controller.groups, isEmpty);
      expect(controller.isRealtimeSelected, isTrue);
    });

    test('createGroup ignores duplicate names', () async {
      await controller.loadStore();
      controller.createGroup('Work', AppConstants.groupColors.first);
      controller.createGroup('work', AppConstants.groupColors.last);

      expect(controller.groups.length, 1);
      expect(controller.groups.first.color, AppConstants.groupColors.first);
    });

    test('addClipboardItem inserts item into realtime', () async {
      await controller.loadStore();
      final item = ClipboardItem(
        id: 'x',
        type: ClipboardItemType.text,
        text: 'hello',
        timestamp: now,
      );

      controller.addClipboardItem(item);

      expect(controller.store.realtime.length, 1);
      expect(controller.store.realtime.first.text, 'hello');
    });

    test('selecting nonexistent group falls back to realtime', () async {
      await controller.loadStore();
      controller.selectGroup('missing');

      expect(controller.isRealtimeSelected, isTrue);
    });

    test('notifies listeners on state changes', () async {
      await controller.loadStore();
      var callCount = 0;
      controller.addListener(() => callCount++);

      controller.switchTheme('light');
      await Future<void>.value();

      expect(callCount, greaterThan(0));
    });
  });
}
