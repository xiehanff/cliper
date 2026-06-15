import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../application/controllers/app_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/clipboard_item.dart';
import '../../../domain/enums/clipboard_item_type.dart';
import '../sidebar/dragged_item.dart';
import 'time_formatter.dart';

class ItemCardWidget extends StatefulWidget {
  final ClipboardItem item;
  final String? groupId;

  const ItemCardWidget({
    super.key,
    required this.item,
    required this.groupId,
  });

  @override
  State<ItemCardWidget> createState() => _ItemCardWidgetState();
}

class _ItemCardWidgetState extends State<ItemCardWidget> {
  bool _hover = false;
  String? _imageSubtitle;

  @override
  void initState() {
    super.initState();
    if (widget.item.type == ClipboardItemType.image) {
      _computeImageSubtitle();
    }
  }

  @override
  void didUpdateWidget(covariant ItemCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.type == ClipboardItemType.image &&
        widget.item.image != oldWidget.item.image) {
      _computeImageSubtitle();
    }
  }

  Future<void> _computeImageSubtitle() async {
    final imageLoader =
        Provider.of<AppController>(context, listen: false).imageLoader;
    if (imageLoader == null) return;

    final info = await imageLoader.resolveImageInfo(widget.item.image);
    if (info == null) return;

    if (mounted) {
      setState(
          () => _imageSubtitle = '${info.format} ${info.width}×${info.height}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    final card = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onDoubleTap: _activateItem,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.fromLTRB(
            14,
            widget.item.type == ClipboardItemType.image ? 14 : 12,
            14,
            widget.item.type == ClipboardItemType.image ? 14 : 12,
          ),
          decoration: BoxDecoration(
            color: _hover ? theme.cardHover : theme.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: _hover ? 6 : 3,
                offset: _hover ? const Offset(0, 2) : const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _TypeIcon(type: widget.item.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _titleForType(widget.item.type),
                      style: TextStyle(
                        color: theme.primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitleForItem(widget.item),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'GoogleSansMono',
                        fontFamilyFallback: const ['PingFang SC'],
                        fontSize: 11,
                        height: 1.35,
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.item.type == ClipboardItemType.image)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _ImageThumbnail(item: widget.item),
                ),
              const SizedBox(width: 12),
              Text(
                formatTimestamp(widget.item.timestamp),
                style: TextStyle(
                  color: theme.secondaryText,
                  fontSize: 10,
                ),
              ),
              if (_hover)
                GestureDetector(
                  onTap: _deleteItem,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: theme.secondaryText,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return Draggable<DraggedItem>(
      data: DraggedItem(widget.item.id, widget.groupId),
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.86,
          child: SizedBox(width: 280, child: _DragPreview(item: widget.item)),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: card,
    );
  }

  String _titleForType(ClipboardItemType type) {
    return switch (type) {
      ClipboardItemType.text => 'Text',
      ClipboardItemType.image => 'Image',
      ClipboardItemType.file => 'File',
      ClipboardItemType.json => 'JSON',
      ClipboardItemType.url => 'URL',
    };
  }

  String _subtitleForItem(ClipboardItem item) {
    return switch (item.type) {
      ClipboardItemType.text => item.text,
      ClipboardItemType.image => _imageSubtitle ?? '',
      ClipboardItemType.file => item.files.join('\n'),
      ClipboardItemType.json => item.text,
      ClipboardItemType.url => item.text,
    };
  }

  void _activateItem() {
    Provider.of<AppController>(
      context,
      listen: false,
    ).activateItem(widget.item.id, groupId: widget.groupId);
  }

  void _deleteItem() {
    Provider.of<AppController>(
      context,
      listen: false,
    ).deleteItem(widget.item.id, groupId: widget.groupId);
  }
}

class _DragPreview extends StatelessWidget {
  final ClipboardItem item;

  const _DragPreview({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor),
      ),
      child: Text(
        _subtitle(item),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: theme.primaryText, fontSize: 12),
      ),
    );
  }

  String _subtitle(ClipboardItem clipboardItem) {
    return switch (clipboardItem.type) {
      ClipboardItemType.text => clipboardItem.text,
      ClipboardItemType.image => 'Image',
      ClipboardItemType.file => clipboardItem.files.join('\n'),
      ClipboardItemType.json => clipboardItem.text,
      ClipboardItemType.url => clipboardItem.text,
    };
  }
}

class _TypeIcon extends StatelessWidget {
  final ClipboardItemType type;

  const _TypeIcon({required this.type});

  String _assetPath(ClipboardItemType t) {
    return switch (t) {
      ClipboardItemType.text => 'assets/icons/text_cate.png',
      ClipboardItemType.image => 'assets/icons/image_cate.png',
      ClipboardItemType.file => 'assets/icons/file_cate.png',
      ClipboardItemType.json => 'assets/icons/json_cate.png',
      ClipboardItemType.url => 'assets/icons/url_cate.png',
    };
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: SizedBox(
        width: 52,
        height: 52,
        child: Image.asset(
          _assetPath(type),
          width: 52,
          height: 52,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _ImageThumbnail extends StatefulWidget {
  final ClipboardItem item;

  const _ImageThumbnail({required this.item});

  @override
  State<_ImageThumbnail> createState() => _ImageThumbnailState();
}

class _ImageThumbnailState extends State<_ImageThumbnail> {
  ImageProvider? _imageProvider;

  @override
  void initState() {
    super.initState();
    _imageProvider = _buildImageProvider(widget.item.image);
  }

  @override
  void didUpdateWidget(covariant _ImageThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.image != widget.item.image) {
      _imageProvider = _buildImageProvider(widget.item.image);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _imageProvider;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 96,
        height: 96,
        child: imageProvider == null
            ? Container(color: Colors.grey[300])
            : Image(
                image: imageProvider,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey[300]),
              ),
      ),
    );
  }

  ImageProvider? _buildImageProvider(String image) {
    final imageLoader =
        Provider.of<AppController>(context, listen: false).imageLoader;
    if (imageLoader == null) return null;
    return imageLoader.buildImageProvider(image);
  }
}
