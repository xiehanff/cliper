import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../application/controllers/app_controller.dart';
import '../application/services/clipboard_history_service_impl.dart';
import '../application/services/group_service_impl.dart';
import '../core/utils/app_logger.dart';
import '../core/utils/id_generator.dart';
import '../infrastructure/desktop/clipboard/clipboard_monitor_manager.dart';
import '../infrastructure/desktop/clipboard/clipboard_writer_impl.dart';
import '../infrastructure/desktop/hotkey/hotkey_manager_service.dart';
import '../infrastructure/desktop/launch/launch_at_startup_service_impl.dart';
import '../infrastructure/desktop/tray/tray_manager_service.dart';
import '../infrastructure/desktop/viewport/macos_viewport_service.dart';
import '../infrastructure/desktop/viewport/windows_viewport_service.dart';
import '../infrastructure/models/store_serializer.dart';
import '../infrastructure/persistence/clipboard_store_local_data_source.dart';
import 'app.dart';

void runCliperApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  final logger = LoggerProvider.instance;
  final idGenerator = IdGeneratorProvider.instance;

  final storeRepository = ClipboardStoreLocalDataSource(
    serializer: StoreSerializer(logger: logger),
    logger: logger,
  );

  final historyService = ClipboardHistoryServiceImpl(
    idGenerator: idGenerator,
    clock: () => DateTime.now().millisecondsSinceEpoch,
  );

  final groupService = GroupServiceImpl(
    idGenerator: idGenerator,
    clock: () => DateTime.now().millisecondsSinceEpoch,
  );

  final windowController = Platform.isMacOS
      ? MacOSViewportService(logger: logger)
      : WindowsViewportService(logger: logger);
  final clipboardWriter = ClipboardWriterImpl(logger: logger);
  final hotkeyService = HotkeyManagerService(
    onTriggered: () => windowController.toggle(),
    logger: logger,
  );
  final launchService = LaunchAtStartupServiceImpl(logger: logger);

  await windowController.initialize();

  final appController = AppController(
    storeRepository: storeRepository,
    historyService: historyService,
    groupService: groupService,
    clipboardWriter: clipboardWriter,
    windowController: windowController,
    hotkeyService: hotkeyService,
    launchService: launchService,
    logger: logger,
  );

  final clipboardMonitor = ClipboardMonitorManager(
    appController: appController,
    logger: logger,
    idGenerator: idGenerator,
    clock: () => DateTime.now().millisecondsSinceEpoch,
  );

  final trayService = TrayManagerService(
    windowController: windowController,
    onQuit: () async {
      await windowManager.destroy();
      exit(0);
    },
    logger: logger,
  );

  runApp(
    ChangeNotifierProvider<AppController>(
      create: (_) => appController,
      child: const CliperApp(),
    ),
  );

  await _startServices(
    trayService: trayService,
    hotkeyService: hotkeyService,
    launchService: launchService,
    clipboardMonitor: clipboardMonitor,
    appController: appController,
  );
}

Future<void> _startServices({
  required TrayManagerService trayService,
  required HotkeyManagerService hotkeyService,
  required LaunchAtStartupServiceImpl launchService,
  required ClipboardMonitorManager clipboardMonitor,
  required AppController appController,
}) async {
  await trayService.initialize();
  await appController.loadStore();

  await hotkeyService.register(appController.currentShortcut);
  await launchService.setEnabled(appController.autoLaunch);

  clipboardMonitor.start();
}
