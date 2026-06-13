import '../../core/utils/id_generator.dart';
import '../../domain/entities/clipboard_group.dart';
import '../../domain/entities/clipboard_item.dart';
import '../../domain/entities/clipboard_store.dart';
import '../../domain/services/group_service.dart';

class GroupServiceImpl implements GroupService {
  final IdGenerator _idGenerator;
  final int Function() _clock;

  GroupServiceImpl({
    required IdGenerator idGenerator,
    required int Function() clock,
  })  : _idGenerator = idGenerator,
        _clock = clock;

  @override
  ClipboardStore createGroup(ClipboardStore store, String name, String color) {
    final group = ClipboardGroup(
      id: _idGenerator.generate(),
      name: name,
      color: color,
    );
    return store.copyWith(groups: [...store.groups, group]);
  }

  @override
  ClipboardStore deleteGroup(ClipboardStore store, String groupId) {
    return store.copyWith(
      groups: store.groups.where((g) => g.id != groupId).toList(),
    );
  }

  @override
  ClipboardStore renameGroup(
      ClipboardStore store, String groupId, String name) {
    return _updateGroup(store, groupId, (group) => group.copyWith(name: name));
  }

  @override
  ClipboardStore updateGroupColor(
      ClipboardStore store, String groupId, String color) {
    return _updateGroup(
        store, groupId, (group) => group.copyWith(color: color));
  }

  @override
  ClipboardStore deleteItemFromGroup(
    ClipboardStore store,
    String groupId,
    String itemId,
  ) {
    return store.copyWith(
      groups: store.groups.map((group) {
        if (group.id != groupId) return group;
        return group.copyWith(
          items: group.items.where((it) => it.id != itemId).toList(),
        );
      }).toList(),
    );
  }

  @override
  ClipboardStore moveItem(
    ClipboardStore store, {
    required String? sourceGroupId,
    required String? targetGroupId,
    required String itemId,
  }) {
    // realtime -> group: copy without removing from realtime
    if (sourceGroupId == null && targetGroupId != null) {
      final sourceItem = _findItem(store, sourceGroupId, itemId);
      if (sourceItem == null) return store;
      final copy = sourceItem.copyWith(
        id: _idGenerator.generate(),
        timestamp: _clock(),
      );
      return _insertItem(store, targetGroupId, copy);
    }

    // group -> realtime or group -> group: migrate
    final removal = _removeItem(store, sourceGroupId, itemId);
    if (removal == null) return store;

    final (sourceItem, storeAfterRemoval) = removal;
    final migrated = sourceItem.copyWith(timestamp: _clock());
    if (targetGroupId == null) {
      return storeAfterRemoval.copyWith(
        realtime: [migrated, ...storeAfterRemoval.realtime],
      );
    }
    return _insertItem(storeAfterRemoval, targetGroupId, migrated);
  }

  ClipboardItem? _findItem(
    ClipboardStore store,
    String? groupId,
    String itemId,
  ) {
    if (groupId == null) {
      final index = store.realtime.indexWhere((it) => it.id == itemId);
      return index < 0 ? null : store.realtime[index];
    }
    for (final group in store.groups) {
      if (group.id != groupId) continue;
      final index = group.items.indexWhere((it) => it.id == itemId);
      return index < 0 ? null : group.items[index];
    }
    return null;
  }

  ClipboardStore _updateGroup(
    ClipboardStore store,
    String groupId,
    ClipboardGroup Function(ClipboardGroup) updater,
  ) {
    return store.copyWith(
      groups: store.groups.map((group) {
        return group.id == groupId ? updater(group) : group;
      }).toList(),
    );
  }

  (ClipboardItem, ClipboardStore)? _removeItem(
      ClipboardStore store, String? groupId, String itemId) {
    if (groupId == null) {
      final index = store.realtime.indexWhere((it) => it.id == itemId);
      if (index < 0) return null;
      final item = store.realtime[index];
      final realtime = [
        ...store.realtime.sublist(0, index),
        ...store.realtime.sublist(index + 1),
      ];
      return (item, store.copyWith(realtime: realtime));
    }

    ClipboardItem? removed;
    final groups = store.groups.map((group) {
      if (group.id != groupId) return group;
      final items = group.items.where((it) {
        if (it.id == itemId) {
          removed = it;
          return false;
        }
        return true;
      }).toList();
      return group.copyWith(items: items);
    }).toList();
    if (removed == null) return null;
    return (removed!, store.copyWith(groups: groups));
  }

  ClipboardStore _insertItem(
      ClipboardStore store, String groupId, ClipboardItem item) {
    return store.copyWith(
      groups: store.groups.map((group) {
        if (group.id != groupId) return group;
        return group.copyWith(items: [item, ...group.items]);
      }).toList(),
    );
  }
}
