import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../application/controllers/app_controller.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

class SettingsPanelWidget extends StatelessWidget {
  final VoidCallback onClose;

  const SettingsPanelWidget({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final controller = Provider.of<AppController>(context);
    final l10n = AppLocalizations.of(context);

    return TapRegion(
      onTapOutside: (_) => onClose(),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(top: 12, right: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.settings,
                  style: TextStyle(
                    color: theme.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '开机自启动',
                        style: TextStyle(
                          color: theme.primaryText,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _statusText(
                            controller.currentLanguage, controller.autoLaunch),
                        style: TextStyle(
                          color: theme.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: controller.autoLaunch,
                  onChanged: (value) => controller.setAutoLaunch(value),
                  activeThumbColor: theme.purpleAccent,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onClose,
                style: TextButton.styleFrom(
                  foregroundColor: theme.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: BorderSide(color: theme.accent),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
                child: const Text('关闭'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusText(String language, bool enabled) {
    if (language == 'en') {
      return enabled
          ? 'App will launch on system startup'
          : 'App will not launch on system startup';
    }
    return enabled ? '应用将在系统启动时自动运行' : '应用不会随系统启动';
  }
}
