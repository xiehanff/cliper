import '../entities/clipboard_store.dart';

abstract interface class StoreRepository {
  Future<ClipboardStore> load();
  Future<void> save(ClipboardStore store);
}
