import 'dart:io';
import 'dart:async';

import 'package:tray_manager/tray_manager.dart';

import '../../../core/utils/app_logger.dart';
import '../../../domain/services/viewport_controller.dart';

class TrayManagerService with TrayListener {
  final ViewportController _windowController;
  final void Function() _onQuit;
  final AppLogger _logger;
  bool _initialized = false;

  TrayManagerService({
    required ViewportController windowController,
    required void Function() onQuit,
    required AppLogger logger,
  })  : _windowController = windowController,
        _onQuit = onQuit,
        _logger = logger;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    trayManager.addListener(this);

    try {
      await trayManager.setIcon(_trayIconPath());
      await trayManager.setToolTip('Cliper');
      await _setMenu();
      _logger.info('Tray initialized');
    } catch (e, stack) {
      _logger.error('Failed to initialize tray', error: e, stackTrace: stack);
    }
  }

  Future<void> _setMenu() async {
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(
            key: 'show',
            label: 'Show / Hide',
            onClick: (_) => _windowController.toggle(),
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'quit',
            label: 'Quit',
            onClick: (_) => _quit(),
          ),
        ],
      ),
    );
  }

  Future<void> dispose() async {
    trayManager.removeListener(this);
    try {
      await trayManager.destroy();
    } catch (e) {
      _logger.warning('Failed to destroy tray: $e');
    }
  }

  @override
  void onTrayIconMouseDown() {
  }

  @override
  void onTrayIconMouseUp() {
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        _windowController.toggle();
        return;
      case 'quit':
        _quit();
        return;
    }
  }

  void _quit() {
    _logger.info('Quitting from tray menu');
    _onQuit();
  }

  String _trayIconPath() {
    return Platform.isWindows ? 'assets/tray_icon.ico' : 'assets/icon.png';
  }
}
