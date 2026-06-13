import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../application/controllers/app_controller.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/clipboard_group.dart';
import 'color_dot.dart';
import 'dragged_item.dart';

class SidebarTab extends StatefulWidget {
  final bool isRealtime;
  final ClipboardGroup? group;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const SidebarTab.realtime({
    super.key,
    required this.selected,
    required this.onTap,
  })  : isRealtime = true,
        group = null,
        onDelete = null;

  const SidebarTab.group({
    super.key,
    required this.group,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  }) : isRealtime = false;

  @override
  State<SidebarTab> createState() => _SidebarTabState();
}

class _SidebarTabState extends State<SidebarTab> {
  bool _hover = false;
  bool _pickerOpen = false;

  void _openPicker() => setState(() => _pickerOpen = true);
  void _closePicker() => setState(() => _pickerOpen = false);

  void _changeColor(String color) {
    final group = widget.group;
    if (group == null) return;
    Provider.of<AppController>(context, listen: false)
        .updateGroupColor(group.id, color);
    _closePicker();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final name = widget.isRealtime
        ? AppLocalizations.of(context).realtime
        : (widget.group?.name ?? '');
    final color = widget.group?.color ?? AppConstants.groupColors.first;

    final targetGroupId = widget.isRealtime ? null : widget.group?.id;
    Widget tab = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: widget.selected
                  ? theme.purpleAccentDark
                  : (_hover ? theme.purpleAccentLight : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                if (!widget.isRealtime)
                  GestureDetector(
                    onTap: _openPicker,
                    behavior: HitTestBehavior.opaque,
                    child: ColorDot(
                      color: color,
                      size: 10,
                      selected: false,
                      borderColor: theme.brightness == Brightness.light
                          ? Colors.black.withValues(alpha: 0.12)
                          : Colors.transparent,
                    ),
                  ),
                if (!widget.isRealtime) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: widget.selected ? Colors.white : theme.primaryText,
                      fontSize: 13,
                      fontWeight:
                          widget.selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!widget.isRealtime)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _hover ? 1 : 0,
                        duration: const Duration(milliseconds: 120),
                        child: IgnorePointer(
                          ignoring: !_hover,
                          child: GestureDetector(
                            onTap: widget.onDelete,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: widget.selected
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : theme.secondaryText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (_pickerOpen && !widget.isRealtime) {
      tab = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          tab,
          const SizedBox(height: 4),
          Container(
            margin: const EdgeInsets.only(left: 8, right: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: theme.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: AppConstants.groupColors
                  .map(
                    (c) => ColorDot(
                      color: c,
                      size: 20,
                      selected: c == color,
                      onTap: () => _changeColor(c),
                      borderColor: theme.brightness == Brightness.light
                          ? Colors.black.withValues(alpha: 0.12)
                          : Colors.transparent,
                      selectedBorderColor:
                          theme.brightness == Brightness.light
                              ? Colors.black.withValues(alpha: 0.35)
                              : Colors.white,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TapRegion(
        onTapOutside: (_) => _closePicker(),
        child: DragTarget<DraggedItem>(
          onWillAcceptWithDetails: (_) => true,
          onAcceptWithDetails: (details) {
            Provider.of<AppController>(context, listen: false).moveItem(
              sourceGroupId: details.data.sourceGroupId,
              targetGroupId: targetGroupId,
              itemId: details.data.itemId,
            );
          },
          builder: (context, candidateData, rejectedData) {
            return Container(
              decoration: BoxDecoration(
                color: candidateData.isNotEmpty
                    ? theme.purpleAccent.withValues(alpha: 0.12)
                    : Colors.transparent,
              ),
              child: tab,
            );
          },
        ),
      ),
    );
  }
}
