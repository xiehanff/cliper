import '../entities/clipboard_item.dart';
import '../entities/clipboard_store.dart';

abstract interface class ClipboardHistoryService {
  ClipboardStore addItem(ClipboardStore store, ClipboardItem item);
  ClipboardStore activateItem(ClipboardStore store, String itemId);
  ClipboardStore deleteItem(ClipboardStore store, String itemId);
}
