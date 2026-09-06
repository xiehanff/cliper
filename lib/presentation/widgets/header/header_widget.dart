import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../../../application/controllers/app_controller.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/shortcut_label.dart';

class HeaderWidget extends StatefulWidget {
  final String title;
  final VoidCallback? onDragStart;
  final bool settingsOpen;
  final VoidCallback onSettingsToggle;
  final bool showWindowControls;

  const HeaderWidget({
    super.key,
    required this.title,
    this.onDragStart,
    required this.settingsOpen,
    required this.onSettingsToggle,
    this.showWindowControls = false,
  });

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> with WindowListener {
  final FocusNode _keyboardFocus = FocusNode();
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    if (widget.showWindowControls) {
      windowManager.addListener(this);
      _syncMaximizedState();
    }
  }

  @override
  void dispose() {
    if (widget.showWindowControls) {
      windowManager.removeListener(this);
    }
    _keyboardFocus.dispose();
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  /// Initialize the maximized state from the native window. window_manager
  /// may be unavailable (e.g. widget tests), so failures are swallowed.
  Future<void> _syncMaximizedState() async {
    try {
      final bool isMaximized = await windowManager.isMaximized();
      if (mounted && isMaximized != _isMaximized) {
        setState(() => _isMaximized = isMaximized);
      }
    } catch (_) {
      // window_manager not available.
    }
  }

  Future<void> _toggleMaximized() async {
    try {
      if (await windowManager.isMaximized()) {
        await windowManager.unmaximize();
      } else {
        await windowManager.maximize();
      }
    } catch (_) {
      // window_manager not available.
    }
  }

  Future<void> _runGuarded(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // window_manager not available.
    }
  }

  void _toggleRecording() {
    final controller = Provider.of<AppController>(context, listen: false);
    if (controller.isShortcutRecording) {
      controller.cancelShortcutRecording();
      _keyboardFocus.unfocus();
    } else {
      controller.startShortcutRecording();
      _keyboardFocus.requestFocus();
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    final controller = Provider.of<AppController>(context, listen: false);
    final wasRecording = controller.isShortcutRecording;
    controller.handleShortcutRecordingKeyEvent(event);
    if (wasRecording && !controller.isShortcutRecording) {
      _keyboardFocus.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AppController>(context);
    final theme = AppTheme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF000000)
            : const Color(0xFFF0F0F0),
        border: Border(bottom: BorderSide(color: theme.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DragToMoveArea(
              onDragStart: widget.onDragStart,
              onDoubleTap: widget.showWindowControls ? _toggleMaximized : null,
              child: Row(
                children: [
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.accent, AppColors.accentDark],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ).createShader(bounds),
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontFamily: 'GBaiMarkerPen',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  KeyboardListener(
                    focusNode: _keyboardFocus,
                    onKeyEvent: _handleKeyEvent,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (controller.supportsGlobalShortcut) ...[
                          _ToolIconButton(
                            tooltip: AppLocalizations.of(context).shortcut,
                            onTap: _toggleRecording,
                            highlighted: controller.isShortcutRecording,
                            icon: Icon(
                              Icons.keyboard_outlined,
                              size: 18,
                              color: controller.isShortcutRecording
                                  ? Colors.white
                                  : theme.secondaryText,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _ShortcutChip(
                            recording: controller.isShortcutRecording,
                            shortcut: controller.currentShortcut,
                          ),
                          const SizedBox(width: 12),
                        ],
                        _ToolIconButton(
                          tooltip: AppLocalizations.of(context).theme,
                          onTap: () => controller.switchTheme(
                            controller.currentTheme == AppConstants.defaultTheme
                                ? AppConstants.supportedThemes[1]
                                : AppConstants.defaultTheme,
                          ),
                          icon: Icon(
                            controller.currentTheme == AppConstants.defaultTheme
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            size: 18,
                            color: theme.secondaryText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _ToolIconButton(
                          tooltip: AppLocalizations.of(context).language,
                          onTap: () => controller.switchLanguage(
                            controller.currentLanguage ==
                                    AppConstants.supportedLanguages[0]
                                ? AppConstants.supportedLanguages[1]
                                : AppConstants.supportedLanguages[0],
                          ),
                          icon: Icon(
                            Icons.language_outlined,
                            size: 18,
                            color: theme.secondaryText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _ToolIconButton(
                          tooltip: AppLocalizations.of(context).settings,
                          onTap: widget.onSettingsToggle,
                          highlighted: widget.settingsOpen,
                          icon: Icon(
                            Icons.settings_outlined,
                            size: 18,
                            color: widget.settingsOpen
                                ? Colors.white
                                : theme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.showWindowControls) ...[
            const SizedBox(width: 8),
            _WindowControls(
              isMaximized: _isMaximized,
              onToggleMaximized: _toggleMaximized,
              onMinimize: () => _runGuarded(windowManager.minimize),
              onClose: () => _runGuarded(windowManager.close),
            ),
          ],
        ],
      ),
    );
  }
}

/// A drag-to-move region that also recognizes double taps without delaying
/// descendant buttons.
///
/// window_manager's [DragToMoveArea] also registers an [DoubleTapGestureRecognizer].
/// A double tap recognizer holds the gesture arena for ~300ms after every
/// single tap (see `GestureArenaManager.hold`), which makes every button
/// underneath (theme, language, settings, …) feel laggy.
/// [TapAndPanGestureRecognizer] does not eagerly win ordinary taps, so
/// descendant buttons resolve immediately; it still wins drags and exposes the
/// consecutive tap count needed for double-click maximize/restore.
class _DragToMoveArea extends StatelessWidget {
  final VoidCallback? onDragStart;
  final VoidCallback? onDoubleTap;
  final Widget child;

  const _DragToMoveArea({
    required this.child,
    this.onDragStart,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: <Type, GestureRecognizerFactory>{
        TapAndPanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapAndPanGestureRecognizer>(
          () => TapAndPanGestureRecognizer(),
          (TapAndPanGestureRecognizer instance) {
            instance.onDragStart = (_) {
              onDragStart?.call();
            };
            instance.onTapUp = (TapDragUpDetails details) {
              if (onDoubleTap != null && details.consecutiveTapCount == 2) {
                onDoubleTap?.call();
              }
            };
          },
        ),
      },
      child: child,
    );
  }
}

/// The minimize / maximize / close buttons (Linux custom title bar).
///
/// Kept as a sibling of the drag region, so clicks resolve immediately
/// instead of competing with the drag area's gesture recognizers.
class _WindowControls extends StatelessWidget {
  final bool isMaximized;
  final VoidCallback onToggleMaximized;
  final VoidCallback onMinimize;
  final VoidCallback onClose;

  const _WindowControls({
    required this.isMaximized,
    required this.onToggleMaximized,
    required this.onMinimize,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowButton(
          tooltip: l10n.minimize,
          color: theme.secondaryText,
          icon: const Icon(Icons.remove_rounded, size: 18),
          onPressed: onMinimize,
        ),
        _WindowButton(
          tooltip: isMaximized ? l10n.restore : l10n.maximize,
          color: theme.secondaryText,
          icon: Icon(
            isMaximized ? Icons.filter_none_rounded : Icons.crop_square_rounded,
            size: 18,
            color: theme.secondaryText,
          ),
          onPressed: onToggleMaximized,
        ),
        _WindowButton(
          tooltip: l10n.close,
          color: theme.secondaryText,
          isClose: true,
          icon: const Icon(Icons.close_rounded, size: 18),
          onPressed: onClose,
        ),
      ],
    );
  }
}

class _WindowButton extends StatelessWidget {
  final String tooltip;
  final Widget icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isClose;

  const _WindowButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isClose = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 50,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          shape: const RoundedRectangleBorder(),
          hoverColor: isClose ? Colors.red : color.withValues(alpha: 0.08),
        ),
        onPressed: onPressed,
        icon: icon,
      ),
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  final bool recording;
  final String shortcut;

  const _ShortcutChip({
    required this.recording,
    required this.shortcut,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final controller = Provider.of<AppController>(context, listen: false);
    final label = recording
        ? l10n.waitingForKey
        : platformAwareShortcutLabel(shortcut, controller.isMacOS);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
        border: recording ? Border.all(color: theme.purpleAccentDark) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: recording
              ? theme.purpleAccentDark
              : theme.purpleAccentDark.withValues(alpha: 0.8),
          fontSize: 12,
          fontWeight: recording ? FontWeight.w600 : FontWeight.w500,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _ToolIconButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onTap;
  final Widget icon;
  final bool highlighted;

  const _ToolIconButton({
    required this.tooltip,
    required this.onTap,
    required this.icon,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: highlighted ? theme.purpleAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: icon,
        ),
      ),
    );
  }
}
