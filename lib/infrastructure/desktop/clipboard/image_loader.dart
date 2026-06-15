import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show instantiateImageCodec;

import 'package:flutter/material.dart';

import '../../../core/utils/app_logger.dart';
import '../../../domain/services/image_loader_service.dart';

class ImageLoaderServiceImpl implements ImageLoaderService {
  final AppLogger _logger;

  ImageLoaderServiceImpl({required AppLogger logger}) : _logger = logger;

  @override
  ImageProvider? buildImageProvider(String image) {
    if (image.isEmpty) return null;

    if (image.startsWith('data:')) {
      final bytes = _decodeDataUrl(image);
      if (bytes != null) return MemoryImage(bytes);
      return null;
    }

    if (image.isNotEmpty) return FileImage(File(image));
    return null;
  }

  @override
  Future<LoadedImageInfo?> resolveImageInfo(String image) async {
    try {
      Uint8List? bytes;
      String format = '';

      if (image.startsWith('data:')) {
        final mimeEnd = image.indexOf(';');
        final mime = image.substring(0, mimeEnd);
        format = mime.contains('png') ? 'PNG' : 'JPEG';
        final comma = image.indexOf(',');
        if (comma < 0) return null;
        bytes = base64Decode(image.substring(comma + 1));
      } else if (image.isNotEmpty) {
        final ext = image.split('.').last.toUpperCase();
        format = ext == 'PNG' ? 'PNG' : 'JPEG';
        final file = File(image);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        }
      }

      if (bytes == null) return null;
      final codec = await instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final w = frame.image.width;
      final h = frame.image.height;
      return LoadedImageInfo(format: format, width: w, height: h);
    } catch (e) {
      _logger.warning('Failed to resolve image info: $e');
      return null;
    }
  }

  Uint8List? _decodeDataUrl(String dataUrl) {
    final commaIndex = dataUrl.indexOf(',');
    if (commaIndex < 0) return null;
    try {
      return base64Decode(dataUrl.substring(commaIndex + 1));
    } catch (e) {
      _logger.warning('Failed to decode data URL: $e');
      return null;
    }
  }
}
