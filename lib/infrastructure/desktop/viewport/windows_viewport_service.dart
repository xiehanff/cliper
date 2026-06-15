import 'dart:async';
import 'dart:ui';

import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/utils/app_logger.dart';
import '../../../domain/services/viewport_controller.dart';

const _viewportWidth = 780.0;
const _viewportHeight = 720.0;
const _viewportMinWidth = 760.0;
const _viewportMinHeight = 640.0;

class WindowsViewportService implements ViewportController {
  final AppLogger _logger;
  bool _isVisible = false;
  bool _isTransitioning = false;
  bool _initialized = false;

  @override
  bool get isVisible => _isVisible;

  WindowsViewportService({required AppLogger logger}) : _logger = logger;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await windowManager.ensureInitialized();
    windowManager.addListener(_ViewportListener(this));
    await windowManager.setPreventClose(true);

    const windowOptions = WindowOptions(
      size: Size(_viewportWidth, _viewportHeight),
      minimumSize: Size(_viewportMinWidth, _viewportMinHeight),
      center: true,
      alwaysOnTop: true,
      skipTaskbar: true,
      title: 'CLIPER',
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
      backgroundColor: Color(0x00000000),
    );

    await windowManager.waitUntilReadyToShow(
      windowOptions,
      () async {
        await windowManager.setMinimumSize(
          const Size(_viewportMinWidth, _viewportMinHeight),
        );
        await windowManager.hide();
        _isVisible = false;
      },
    );

    _logger.info('Windows viewport initialized');
  }

  @override
  Future<void> show() async {
    await _ensureInitialized();
    if (_isVisible || _isTransitioning) return;

    _isTransitioning = true;
    try {
      await _positionViewport();
      await windowManager.show();
      await windowManager.setAlwaysOnTop(true);
      await windowManager.focus();
      _isVisible = true;
      _logger.debug('Viewport shown');
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
      _logger.debug('Viewport hidden');
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

  Future<void> _positionViewport() async {
    try {
      final display = await _targetDisplay();
      final position = display.visiblePosition ?? Offset.zero;
      final size = display.visibleSize ?? display.size;

      final x = position.dx + (size.width - _viewportWidth) / 2;
      final y = position.dy + (size.height - _viewportHeight) / 2;

      final clampedX =
          x.clamp(position.dx, position.dx + size.width - _viewportWidth);
      final clampedY =
          y.clamp(position.dy, position.dy + size.height - _viewportHeight);

      await windowManager.setPosition(Offset(clampedX, clampedY));
    } catch (e, stack) {
      _logger.error('Failed to position viewport', error: e, stackTrace: stack);
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

  void _onViewportFocus() {
    _isVisible = true;
  }

  void _onViewportBlur() {
    unawaited(_handleViewportBlur());
  }

  void _onViewportClose() {
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

  Future<void> _handleViewportBlur() async {
    final visible = await _isNativeVisible();
    if (!visible && !_isVisible) return;
    await hide();
  }
}

class _ViewportListener extends WindowListener {
  final WindowsViewportService _service;

  _ViewportListener(this._service);

  @override
  void onWindowFocus() => _service._onViewportFocus();

  @override
  void onWindowBlur() => _service._onViewportBlur();

  @override
  void onWindowClose() => _service._onViewportClose();
}
