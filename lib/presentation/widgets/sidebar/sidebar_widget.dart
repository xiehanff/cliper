import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../application/controllers/app_controller.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import 'new_group_input.dart';
import 'sidebar_tab.dart';

class SidebarWidget extends StatefulWidget {
  const SidebarWidget({super.key});

  @override
  State<SidebarWidget> createState() => _SidebarWidgetState();
}

class _SidebarWidgetState extends State<SidebarWidget> {
  bool _creating = false;

  void _startCreating() => setState(() => _creating = true);
  void _finishCreating() => setState(() => _creating = false);

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final controller = Provider.of<AppController>(context);

    return Container(
      width: 180,
      decoration: BoxDecoration(color: theme.sidebar),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          const SizedBox(height: 24),
          SidebarTab.realtime(
            selected: controller.isRealtimeSelected,
            onTap: () => controller.selectGroup(null),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: controller.groups.length + (_creating ? 1 : 0),
              itemBuilder: (context, index) {
                if (_creating && index == controller.groups.length) {
                  return NewGroupInput(onDone: _finishCreating);
                }
                final group = controller.groups[index];
                return SidebarTab.group(
                  key: ValueKey(group.id),
                  group: group,
                  selected: controller.currentGroupId == group.id,
                  onTap: () => controller.selectGroup(group.id),
                  onDelete: () => controller.deleteGroup(group.id),
                );
              },
            ),
          ),
          _NewGroupButton(
            onTap: _startCreating,
            enabled: !_creating,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _NewGroupButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool enabled;

  const _NewGroupButton({required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: enabled ? Colors.transparent : theme.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? theme.purpleAccent : theme.cardHover,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 16, color: theme.purpleAccent),
            const SizedBox(width: 6),
            Flexible(
            child: Text(
                l10n.newGroup,
                style: TextStyle(
                  color: enabled ? theme.purpleAccent : theme.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
