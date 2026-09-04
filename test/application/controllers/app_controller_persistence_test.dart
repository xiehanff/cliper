import 'dart:async';

import 'package:cliper/application/controllers/app_controller.dart';
import 'package:cliper/application/controllers/settings_handler.dart';
import 'package:cliper/application/services/clipboard_history_service_impl.dart';
import 'package:cliper/application/services/group_service_impl.dart';
import 'package:cliper/domain/entities/clipboard_item.dart';
import 'package:cliper/domain/entities/clipboard_store.dart';
import 'package:cliper/domain/enums/clipboard_item_type.dart';
import 'package:cliper/domain/repositories/store_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_helpers.dart';

void main() {
  test('persists a later clipboard change after an in-flight save', () async {
    final repository = _BlockingStoreRepository();
    final idGenerator = FakeIdGenerator();
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
    );
    addTearDown(controller.dispose);

    await controller.loadStore();

    controller.addClipboardItem(
      ClipboardItem(
        id: 'first',
        type: ClipboardItemType.text,
        text: 'first',
        timestamp: now,
      ),
    );
    await repository.firstSaveStarted.future;

    now = 2000;
    controller.addClipboardItem(
      ClipboardItem(
        id: 'second',
        type: ClipboardItemType.text,
        text: 'second',
        timestamp: now,
      ),
    );

    expect(repository.saveCount, 1);

    repository.releaseFirstSave.complete();
    await repository.secondSaveCompleted.future;

    expect(repository.saveCount, 2);
    expect(repository.savedStores.last.realtime.first.text, 'second');
    expect(repository.savedStores.last.realtime.length, 2);
  });
}

class _BlockingStoreRepository implements StoreRepository {
  final firstSaveStarted = Completer<void>();
  final releaseFirstSave = Completer<void>();
  final secondSaveCompleted = Completer<void>();
  final List<ClipboardStore> savedStores = <ClipboardStore>[];
  int saveCount = 0;

  @override
  Future<ClipboardStore> load() async => const ClipboardStore();

  @override
  Future<void> save(ClipboardStore store) async {
    saveCount++;
    if (saveCount == 1) {
      firstSaveStarted.complete();
      await releaseFirstSave.future;
    }

    savedStores.add(store);
    if (saveCount == 2 && !secondSaveCompleted.isCompleted) {
      secondSaveCompleted.complete();
    }
  }
}
