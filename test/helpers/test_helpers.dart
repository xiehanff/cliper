import 'package:cliper/core/utils/app_logger.dart';
import 'package:cliper/core/utils/id_generator.dart';
import 'package:cliper/domain/entities/clipboard_store.dart';
import 'package:cliper/domain/repositories/store_repository.dart';

class FakeIdGenerator implements IdGenerator {
  int _counter = 0;

  @override
  String generate() {
    _counter++;
    return 'id-$_counter';
  }
}

class FakeAppLogger implements AppLogger {
  final List<String> logs = <String>[];

  @override
  void debug(String message) => logs.add('DEBUG: $message');

  @override
  void info(String message) => logs.add('INFO: $message');

  @override
  void warning(String message) => logs.add('WARN: $message');

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    logs.add('ERROR: $message');
  }
}

class InMemoryStoreRepository implements StoreRepository {
  ClipboardStore _store = const ClipboardStore();
  int saveCount = 0;

  @override
  Future<ClipboardStore> load() async => _store;

  @override
  Future<void> save(ClipboardStore store) async {
    _store = store;
    saveCount++;
  }
}
