import 'package:cliper/application/controllers/app_controller.dart';
import 'package:cliper/application/controllers/settings_handler.dart';
import 'package:cliper/application/services/clipboard_history_service_impl.dart';
import 'package:cliper/application/services/group_service_impl.dart';
import 'package:cliper/core/utils/app_logger.dart';
import 'package:cliper/core/utils/id_generator.dart';
import 'package:cliper/domain/entities/clipboard_item.dart';
import 'package:cliper/domain/entities/clipboard_store.dart';
import 'package:cliper/domain/repositories/store_repository.dart';
import 'package:cliper/domain/services/clipboard_writer.dart';
import 'package:cliper/domain/services/hotkey_service.dart';
import 'package:cliper/domain/services/launch_at_startup_service.dart';
import 'package:cliper/domain/services/viewport_controller.dart';

class FakeIdGenerator implements IdGenerator {
  int _counter = 0;

  @override
  String generate() {
    _counter++;
    return 'id-$_counter';
  }
}

class FakeAppLogger implements AppLogger {
  @override
  void debug(String message) {}

  @override
  void info(String message) {}

  @override
  void warning(String message) {}

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {}
}

class InMemoryStoreRepository implements StoreRepository {
  ClipboardStore _store = const ClipboardStore();

  @override
  Future<ClipboardStore> load() async => _store;

  @override
  Future<void> save(ClipboardStore store) async {
    _store = store;
  }
}

class FakeClipboardWriter implements ClipboardWriter {
  ClipboardItem? lastWritten;

  @override
  Future<void> write(ClipboardItem item) async {
    lastWritten = item;
  }
}

class FakeWindowController implements ViewportController {
  int showCount = 0;
  int hideCount = 0;
  int toggleCount = 0;
  bool _visible = false;

  @override
  bool get isVisible => _visible;

  @override
  bool get hideWindowAfterItemActivation => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> show() async {
    showCount++;
    _visible = true;
  }

  @override
  Future<void> hide() async {
    hideCount++;
    _visible = false;
  }

  @override
  Future<void> toggle() async {
    toggleCount++;
    _visible = !_visible;
  }
}

class FakeHotkeyService implements HotkeyService {
  String? registeredShortcut;

  @override
  Future<void> register(String shortcut) async {
    registeredShortcut = shortcut;
  }

  @override
  Future<void> unregister() async {
    registeredShortcut = null;
  }
}

class FakeLaunchService implements LaunchAtStartupService {
  bool? enabled;

  @override
  Future<void> setEnabled(bool value) async {
    enabled = value;
  }
}

AppController createTestController() {
  final idGenerator = FakeIdGenerator();
  final fakeLogger = FakeAppLogger();
  return AppController(
    storeRepository: InMemoryStoreRepository(),
    historyService: ClipboardHistoryServiceImpl(
      idGenerator: idGenerator,
      clock: () => 1700000000000,
    ),
    groupService: GroupServiceImpl(
      idGenerator: idGenerator,
      clock: () => 1700000000000,
    ),
    settingsHandler: SettingsHandler(
      hotkeyService: FakeHotkeyService(),
      launchService: FakeLaunchService(),
      logger: fakeLogger,
      supportsGlobalShortcut: true,
    ),
    clipboardWriter: FakeClipboardWriter(),
    windowController: FakeWindowController(),
    logger: fakeLogger,
  );
}
