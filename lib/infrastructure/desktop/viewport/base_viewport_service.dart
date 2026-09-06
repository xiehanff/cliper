import 'dart:async';
import 'dart:ui';

import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/utils/app_logger.dart';
import '../../../domain/services/viewport_controller.dart';

const viewportWidth = 780.0;
const viewportHeight = 720.0;
const viewportMinWidth = 760.0;
const viewportMinHeight = 640.0;

class BaseViewportService implements ViewportController {
  final AppLogger _logger;
  final String _platformLabel;
  final bool _alwaysOnTop;
  final bool _skipTaskbar;
  final bool _hideOnStartup;
  final bool _hideOnBlur;
  final bool _preventClose;
  final bool _focusOnShow;
  final bool _hideWindowAfterItemActivation;
  final bool _minimizeAfterItemActivation;
  final TitleBarStyle _titleBarStyle;
  final bool _windowButtonVisibility;
  bool _isVisible = false;
  bool _isTransitioning = false;
  bool _initialized = false;

  @override
  bool get isVisible => _isVisible;

  @override
  bool get hideWindowAfterItemActivation => _hideWindowAfterItemActivation;

  @override
  bool get minimizeAfterItemActivation => _minimizeAfterItemActivation;

  BaseViewportService({
    required AppLogger logger,
    required String platformLabel,
    bool alwaysOnTop = true,
    bool skipTaskbar = true,
    bool hideOnStartup = true,
    bool hideOnBlur = true,
    bool preventClose = true,
    bool focusOnShow = true,
    bool hideWindowAfterItemActivation = true,
    bool minimizeAfterItemActivation = false,
    TitleBarStyle titleBarStyle = TitleBarStyle.hidden,
    bool windowButtonVisibility = false,
  })  : _logger = logger,
        _platformLabel = platformLabel,
        _alwaysOnTop = alwaysOnTop,
        _skipTaskbar = skipTaskbar,
        _hideOnStartup = hideOnStartup,
        _hideOnBlur = hideOnBlur,
        _preventClose = preventClose,
        _focusOnShow = focusOnShow,
        _hideWindowAfterItemActivation = hideWindowAfterItemActivation,
        _minimizeAfterItemActivation = minimizeAfterItemActivation,
        _titleBarStyle = titleBarStyle,
        _windowButtonVisibility = windowButtonVisibility;
  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await windowManager.ensureInitialized();
    windowManager.addListener(_ViewportListener(this));
    await windowManager.setPreventClose(_preventClose);

    final windowOptions = WindowOptions(
      size: const Size(viewportWidth, viewportHeight),
      minimumSize: const Size(viewportMinWidth, viewportMinHeight),
      center: true,
      alwaysOnTop: _alwaysOnTop,
      skipTaskbar: _skipTaskbar,
      title: 'CLIPER',
      titleBarStyle: _titleBarStyle,
      windowButtonVisibility: _windowButtonVisibility,
      backgroundColor: const Color(0x00000000),
    );

    await windowManager.waitUntilReadyToShow(
      windowOptions,
      () async {
        await windowManager.setMinimumSize(
          const Size(viewportMinWidth, viewportMinHeight),
        );
        if (_hideOnStartup) {
          await windowManager.hide();
          _isVisible = false;
        } else {
          await windowManager.show();
          _isVisible = true;
        }
      },
    );

    _logger.info('$_platformLabel viewport initialized');
  }

  @override
  Future<void> show() async {
    await _ensureInitialized();
    if (_isVisible || _isTransitioning) return;

    _isTransitioning = true;
    try {
      await _positionViewport();
      await windowManager.show();
      await windowManager.setAlwaysOnTop(_alwaysOnTop);
      if (_focusOnShow) {
        await windowManager.focus();
      }
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
  Future<void> minimize() async {
    await _ensureInitialized();
    try {
      await windowManager.minimize();
      _logger.debug('Viewport minimized');
    } catch (e, stack) {
      _logger.error('Failed to minimize viewport',
          error: e, stackTrace: stack);
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

      final x = position.dx + (size.width - viewportWidth) / 2;
      final y = position.dy + (size.height - viewportHeight) / 2;

      final clampedX =
          x.clamp(position.dx, position.dx + size.width - viewportWidth);
      final clampedY =
          y.clamp(position.dy, position.dy + size.height - viewportHeight);

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
    if (!_hideOnBlur) return;
    final visible = await _isNativeVisible();
    if (!visible && !_isVisible) return;
    await hide();
  }

  void handleWindowClose() {
    if (_preventClose) {
      hide();
      return;
    }
    _isVisible = false;
  }
}

class _ViewportListener extends WindowListener {
  final BaseViewportService _service;

  _ViewportListener(this._service);

  @override
  void onWindowFocus() => _service._onViewportFocus();

  @override
  void onWindowBlur() => _service._onViewportBlur();

  @override
  void onWindowClose() => _service.handleWindowClose();
}
