import '../../core/constants/app_constants.dart';
import '../../core/utils/id_generator.dart';
import '../../domain/entities/clipboard_item.dart';
import '../../domain/entities/clipboard_store.dart';
import '../../domain/services/clipboard_history_service.dart';

class ClipboardHistoryServiceImpl implements ClipboardHistoryService {
  final IdGenerator _idGenerator;
  final int Function() _clock;

  ClipboardHistoryServiceImpl({
    required IdGenerator idGenerator,
    required int Function() clock,
  })  : _idGenerator = idGenerator,
        _clock = clock;

  @override
  ClipboardStore addItem(ClipboardStore store, ClipboardItem item) {
    final duplicate = store.realtime.firstWhere(
      (it) => it.type == item.type && it.contentKey == item.contentKey,
      orElse: () => ClipboardItem(id: '', type: item.type, timestamp: 0),
    );
    if (duplicate.id.isNotEmpty) return store;

    final newItem = item.copyWith(
      id: item.id.isEmpty ? _idGenerator.generate() : item.id,
      timestamp: item.timestamp == 0 ? _clock() : item.timestamp,
    );

    var realtime = [newItem, ...store.realtime];
    if (realtime.length > AppConstants.realtimeHistoryLimit) {
      realtime = realtime.sublist(0, AppConstants.realtimeHistoryLimit);
    }
    return store.copyWith(realtime: realtime);
  }

  @override
  ClipboardStore activateItem(ClipboardStore store, String itemId) {
    final index = store.realtime.indexWhere((it) => it.id == itemId);
    if (index <= 0) return store;

    final item = store.realtime[index].copyWith(timestamp: _clock());
    final realtime = [
      item,
      ...store.realtime.sublist(0, index),
      ...store.realtime.sublist(index + 1),
    ];
    return store.copyWith(realtime: realtime);
  }

  @override
  ClipboardStore deleteItem(ClipboardStore store, String itemId) {
    final realtime = store.realtime.where((it) => it.id != itemId).toList();
    return store.copyWith(realtime: realtime);
  }
}
