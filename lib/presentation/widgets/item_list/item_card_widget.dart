import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show instantiateImageCodec;

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
    try {
      Uint8List? bytes;
      String format = '';

      if (widget.item.image.startsWith('data:')) {
        final mimeEnd = widget.item.image.indexOf(';');
        final mime = widget.item.image.substring(0, mimeEnd);
        format = mime.contains('png') ? 'PNG' : 'JPEG';
        final comma = widget.item.image.indexOf(',');
        if (comma < 0) return;
        bytes = base64Decode(widget.item.image.substring(comma + 1));
      } else if (widget.item.image.isNotEmpty) {
        final ext = widget.item.image.split('.').last.toUpperCase();
        format = ext == 'PNG' ? 'PNG' : 'JPEG';
        final file = File(widget.item.image);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        }
      }

      if (bytes == null) return;
      final codec = await instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final w = frame.image.width;
      final h = frame.image.height;
      if (mounted) {
        setState(() => _imageSubtitle = '$format $w×$h');
      }
    } catch (_) {}
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
            widget.item.type == ClipboardItemType.image ? 20 : 12,
            14,
            widget.item.type == ClipboardItemType.image ? 20 : 12,
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
              const SizedBox(width: 10),
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
          child: SizedBox(width: 280, child: _buildDragPreview(theme)),
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
    };
  }

  String _subtitleForItem(ClipboardItem item) {
    return switch (item.type) {
      ClipboardItemType.text => item.text,
      ClipboardItemType.image => _imageSubtitle ?? '',
      ClipboardItemType.file => item.files.join('\n'),
    };
  }

  Widget _buildDragPreview(AppThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor),
      ),
      child: Text(
        _subtitleForItem(widget.item),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: theme.primaryText, fontSize: 12),
      ),
    );
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

class _TypeIcon extends StatelessWidget {
  final ClipboardItemType type;

  const _TypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: theme.cardHover,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        switch (type) {
          ClipboardItemType.text => Icons.text_snippet_outlined,
          ClipboardItemType.image => Icons.image_outlined,
          ClipboardItemType.file => Icons.folder_outlined,
        },
        size: 16,
        color: theme.secondaryText,
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
        width: 72,
        height: 72,
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
    if (image.startsWith('data:')) {
      final bytes = _decodeDataUrl(image);
      if (bytes != null) return MemoryImage(bytes);
    }
    if (image.isNotEmpty) return FileImage(File(image));
    return null;
  }

  Uint8List? _decodeDataUrl(String dataUrl) {
    final commaIndex = dataUrl.indexOf(',');
    if (commaIndex < 0) return null;
    try {
      return base64Decode(dataUrl.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }
}
