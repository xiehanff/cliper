import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/controllers/app_controller.dart';
import '../../core/l10n/app_localizations.dart';
import '../../domain/entities/clipboard_group.dart';
import '../widgets/header/header_widget.dart';
import '../widgets/item_list/item_list_widget.dart';
import '../widgets/settings_panel/settings_panel_widget.dart';
import '../widgets/sidebar/sidebar_widget.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onHeaderDragStart;

  const HomePage({super.key, this.onHeaderDragStart});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _settingsOpen = false;

  void _toggleSettings() => setState(() => _settingsOpen = !_settingsOpen);
  void _closeSettings() => setState(() => _settingsOpen = false);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AppController>(context);
    final l10n = AppLocalizations.forLanguage(controller.currentLanguage);

    final title = controller.isRealtimeSelected
        ? l10n.realtime
        : controller.groups
            .firstWhere(
              (g) => g.id == controller.currentGroupId,
              orElse: () => const ClipboardGroup(id: '', name: ''),
            )
            .name;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Row(
            children: [
              const SidebarWidget(),
              Expanded(
                child: Column(
                  children: [
                    HeaderWidget(
                      title: title,
                      onDragStart: widget.onHeaderDragStart,
                      settingsOpen: _settingsOpen,
                      onSettingsToggle: _toggleSettings,
                    ),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          ItemListWidget(
                            items: controller.currentItems,
                            groupId: controller.currentGroupId,
                          ),
                          if (_settingsOpen)
                            SettingsPanelWidget(onClose: _closeSettings),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
