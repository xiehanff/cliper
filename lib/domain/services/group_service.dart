import '../entities/clipboard_store.dart';

abstract interface class GroupService {
  ClipboardStore createGroup(ClipboardStore store, String name, String color);
  ClipboardStore deleteGroup(ClipboardStore store, String groupId);
  ClipboardStore renameGroup(ClipboardStore store, String groupId, String name);
  ClipboardStore updateGroupColor(
      ClipboardStore store, String groupId, String color);

  ClipboardStore deleteItemFromGroup(
    ClipboardStore store,
    String groupId,
    String itemId,
  );

  /// Moves an item between realtime and groups.
  /// [sourceGroupId] is `null` when the source is realtime.
  /// [targetGroupId] is `null` when the target is realtime.
  ClipboardStore moveItem(
    ClipboardStore store, {
    required String? sourceGroupId,
    required String? targetGroupId,
    required String itemId,
  });
}
