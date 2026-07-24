import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:super_clipboard/super_clipboard.dart' hide ClipboardWriter;

import '../../../core/utils/app_logger.dart';
import '../../../domain/entities/clipboard_item.dart';
import '../../../domain/enums/clipboard_item_type.dart';
import '../../../domain/services/clipboard_writer.dart';

class ClipboardWriterImpl implements ClipboardWriter {
  final AppLogger _logger;

  ClipboardWriterImpl({required AppLogger logger}) : _logger = logger;

  @override
  Future<void> write(ClipboardItem item) async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      _logger.warning('System clipboard is not available');
      return;
    }

    switch (item.type) {
      case ClipboardItemType.text:
      case ClipboardItemType.json:
      case ClipboardItemType.url:
        await _writeText(clipboard, item.text);
      case ClipboardItemType.image:
        await _writeImage(clipboard, item.image);
      case ClipboardItemType.file:
        await _writeFiles(clipboard, item.files);
    }
  }

  Future<void> _writeText(SystemClipboard clipboard, String text) async {
    if (text.isEmpty) return;
    final writer = DataWriterItem();
    writer.add(Formats.plainText(text));
    await clipboard.write([writer]);
  }

  Future<void> _writeFiles(
      SystemClipboard clipboard, List<String> files) async {
    if (files.isEmpty) return;
    final items = <DataWriterItem>[];
    for (final filePath in files) {
      final writer = DataWriterItem();
      writer.add(
        Formats.fileUri(Uri.file(filePath, windows: Platform.isWindows)),
      );
      items.add(writer);
    }
    await clipboard.write(items);
  }

  Future<void> _writeImage(SystemClipboard clipboard, String image) async {
    final bytes = _decodeImage(image);
    if (bytes == null || bytes.isEmpty) {
      _logger.warning('No image data to write back to clipboard');
      return;
    }
    final writer = DataWriterItem();
    writer.add(Formats.png(bytes));
    await clipboard.write([writer]);
  }

  Uint8List? _decodeImage(String image) {
    if (image.isEmpty) return null;
    if (image.startsWith('data:')) {
      final commaIndex = image.indexOf(',');
      if (commaIndex < 0) return null;
      final base64Data = image.substring(commaIndex + 1);
      try {
        return base64Decode(base64Data);
      } catch (e) {
        _logger.warning('Failed to decode base64 image');
        return null;
      }
    }
    try {
      return base64Decode(image);
    } catch (e) {
      _logger.warning('Failed to decode image as base64');
      return null;
    }
  }
}
