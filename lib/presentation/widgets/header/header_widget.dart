import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../application/controllers/app_controller.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'shortcut_formatter.dart';

class HeaderWidget extends StatefulWidget {
  final String title;
  final VoidCallback? onDragStart;
  final bool settingsOpen;
  final VoidCallback onSettingsToggle;

  const HeaderWidget({
    super.key,
    required this.title,
    this.onDragStart,
    required this.settingsOpen,
    required this.onSettingsToggle,
  });

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  bool _recording = false;
  final FocusNode _keyboardFocus = FocusNode();

  @override
  void dispose() {
    _keyboardFocus.dispose();
    super.dispose();
  }

  void _toggleRecording() {
    setState(() => _recording = !_recording);
    if (_recording) {
      _keyboardFocus.requestFocus();
      return;
    }
    _keyboardFocus.unfocus();
  }

  void _cancelRecording() {
    if (!_recording) return;
    setState(() => _recording = false);
    _keyboardFocus.unfocus();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (!_recording || event is! KeyDownEvent) return;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      _cancelRecording();
      return;
    }

    if (isOnlyModifier(key)) return;

    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final hasModifier = pressed.any(
      (k) =>
          k == LogicalKeyboardKey.controlLeft ||
          k == LogicalKeyboardKey.controlRight ||
          k == LogicalKeyboardKey.metaLeft ||
          k == LogicalKeyboardKey.metaRight ||
          k == LogicalKeyboardKey.altLeft ||
          k == LogicalKeyboardKey.altRight ||
          k == LogicalKeyboardKey.shiftLeft ||
          k == LogicalKeyboardKey.shiftRight,
    );
    if (!hasModifier) return;

    final shortcut = formatShortcut(pressed, key);
    Provider.of<AppController>(context, listen: false).setShortcut(shortcut);
    setState(() => _recording = false);
    _keyboardFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AppController>(context);
    final theme = AppTheme.of(context);

    return GestureDetector(
      onPanStart: (_) => widget.onDragStart?.call(),
      behavior: HitTestBehavior.translucent,
      child: Container(
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
                  _ToolIconButton(
                    tooltip: AppLocalizations.of(context).shortcut,
                    onTap: _toggleRecording,
                    highlighted: _recording,
                    icon: Icon(
                      Icons.keyboard_outlined,
                      size: 18,
                      color: _recording
                          ? Colors.white
                          : theme.secondaryText,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _ShortcutChip(
                    recording: _recording,
                    shortcut: controller.currentShortcut,
                  ),
                  const SizedBox(width: 12),
                  _ToolIconButton(
                    tooltip: AppLocalizations.of(context).theme,
                    onTap: () => controller.switchTheme(
                      controller.currentTheme == 'dark' ? 'light' : 'dark',
                    ),
                    icon: Icon(
                      controller.currentTheme == 'dark'
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
                      controller.currentLanguage == 'zh' ? 'en' : 'zh',
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
    final label = recording
        ? l10n.waitingForKey
        : platformAwareShortcutLabel(shortcut);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
        border: recording
            ? Border.all(color: theme.purpleAccentDark)
            : null,
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
