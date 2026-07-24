import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  final FocusNode _keyboardFocus = FocusNode();

  @override
  void dispose() {
    _keyboardFocus.dispose();
    super.dispose();
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
