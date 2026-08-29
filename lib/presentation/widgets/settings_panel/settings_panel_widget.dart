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
            Text(
              l10n.settings,
              style: TextStyle(
                color: theme.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.autoLaunch,
                        style: TextStyle(
                          color: theme.primaryText,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        controller.autoLaunch
                            ? l10n.autoLaunchOn
                            : l10n.autoLaunchOff,
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
          ],
        ),
      ),
    );
  }
}
