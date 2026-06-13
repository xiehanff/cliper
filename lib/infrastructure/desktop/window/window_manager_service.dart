import 'dart:async';
import 'dart:ui';

import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/utils/app_logger.dart';
import '../../../domain/services/window_controller.dart';

const _windowWidth = 780.0;
const _windowHeight = 720.0;
const _windowMinWidth = 760.0;
const _windowMinHeight = 640.0;

class WindowManagerService implements WindowController {
  final AppLogger _logger;
  bool _isVisible = false;
  bool _isTransitioning = false;
  bool _initialized = false;

  @override
  bool get isVisible => _isVisible;

  WindowManagerService({required AppLogger logger}) : _logger = logger;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await windowManager.ensureInitialized();
    windowManager.addListener(_WindowListener(this));
    await windowManager.setPreventClose(true);

    const windowOptions = WindowOptions(
      size: Size(_windowWidth, _windowHeight),
      minimumSize: Size(_windowMinWidth, _windowMinHeight),
      center: true,
      alwaysOnTop: true,
      skipTaskbar: true,
      title: 'CLIPER',
      titleBarStyle: TitleBarStyle.hidden,
      backgroundColor: Color(0x00000000),
    );

    await windowManager.waitUntilReadyToShow(
      windowOptions,
      () async {
        await windowManager.setMinimumSize(
          const Size(_windowMinWidth, _windowMinHeight),
        );
        await windowManager.hide();
        _isVisible = false;
      },
    );

    _logger.info('Window manager initialized');
  }

  @override
  Future<void> show() async {
    await _ensureInitialized();
    if (_isVisible || _isTransitioning) return;

    _isTransitioning = true;
    try {
      await _positionWindow();
      await windowManager.show();
      await windowManager.setAlwaysOnTop(true);
      await windowManager.focus();
      _isVisible = true;
      _logger.debug('Window shown');
    } finally {
      _isTransitioning = false;
    }
  }

  @override
  Future<void> hide() async {
    await _ensureInitialized();
    if (!_isVisible || _isTransitioning) return;

    _isTransitioning = true;
    try {
      await windowManager.hide();
      _isVisible = false;
      _logger.debug('Window hidden');
    } finally {
      _isTransitioning = false;
    }
  }

  @override
  Future<void> toggle() async {
    await _ensureInitialized();
    if (_isTransitioning) return;
    final visible = await _isNativeVisible();
    _isVisible = visible;
    if (visible) {
      await hide();
    } else {
      await show();
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) await initialize();
  }

  Future<void> _positionWindow() async {
    try {
      final display = await _targetDisplay();
      final position = display.visiblePosition ?? Offset.zero;
      final size = display.visibleSize ?? display.size;

      final x = position.dx + (size.width - _windowWidth) / 2;
      final y = position.dy + (size.height - _windowHeight) / 2;

      final clampedX =
          x.clamp(position.dx, position.dx + size.width - _windowWidth);
      final clampedY =
          y.clamp(position.dy, position.dy + size.height - _windowHeight);

      await windowManager.setPosition(Offset(clampedX, clampedY));
    } catch (e, stack) {
      _logger.error('Failed to position window', error: e, stackTrace: stack);
    }
  }

  Future<Display> _targetDisplay() async {
    try {
      final cursor = await screenRetriever.getCursorScreenPoint();
      final displays = await screenRetriever.getAllDisplays();
      for (final display in displays) {
        final pos = display.visiblePosition ?? Offset.zero;
        final size = display.visibleSize ?? display.size;
        final rect = Rect.fromLTWH(pos.dx, pos.dy, size.width, size.height);
        if (rect.contains(cursor)) return display;
      }
    } catch (e, stack) {
      _logger.error('Failed to determine active display',
          error: e, stackTrace: stack);
    }
    return screenRetriever.getPrimaryDisplay();
  }

  void _onWindowFocus() {
    _isVisible = true;
  }

  void _onWindowBlur() {
    unawaited(_handleWindowBlur());
  }

  void _onWindowClose() {
    hide();
  }

  Future<bool> _isNativeVisible() async {
    try {
      return await windowManager.isVisible();
    } catch (e, stack) {
      _logger.error('Failed to query native visibility',
          error: e, stackTrace: stack);
      return _isVisible;
    }
  }

  Future<void> _handleWindowBlur() async {
    final visible = await _isNativeVisible();
    if (!visible && !_isVisible) return;
    await hide();
  }
}

class _WindowListener extends WindowListener {
  final WindowManagerService _service;

  _WindowListener(this._service);

  @override
  void onWindowFocus() => _service._onWindowFocus();

  @override
  void onWindowBlur() => _service._onWindowBlur();

  @override
  void onWindowClose() => _service._onWindowClose();
}
