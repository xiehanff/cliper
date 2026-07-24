import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/clipboard_item.dart';
import 'item_card_widget.dart';

class ItemListWidget extends StatefulWidget {
  final List<ClipboardItem> items;
  final String? groupId;

  const ItemListWidget({
    super.key,
    required this.items,
    this.groupId,
  });

  @override
  State<ItemListWidget> createState() => _ItemListWidgetState();
}

class _ItemListWidgetState extends State<ItemListWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _showTopButton = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final show = _scrollController.offset > 140;
    if (show != _showTopButton) {
      setState(() => _showTopButton = show);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    if (widget.items.isEmpty) {
      return _EmptyState(theme: theme);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Stack(
        children: [
          ScrollConfiguration(
            behavior: _NoScrollbarBehavior(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return ItemCardWidget(
                  key: ValueKey(item.id),
                  item: item,
                  groupId: widget.groupId,
                );
              },
            ),
          ),
          if (_showTopButton)
            Positioned(
              top: 18,
              right: 18,
              child: GestureDetector(
                onTap: _scrollToTop,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.58),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'top',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppThemeData theme;

  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context).empty,
        style: TextStyle(
          color: theme.secondaryText,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
