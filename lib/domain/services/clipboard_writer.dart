import '../entities/clipboard_item.dart';

abstract interface class ClipboardWriter {
  Future<void> write(ClipboardItem item);
}
