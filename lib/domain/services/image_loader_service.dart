import 'package:flutter/material.dart';

class LoadedImageInfo {
  final String format;
  final int width;
  final int height;

  const LoadedImageInfo({
    required this.format,
    required this.width,
    required this.height,
  });
}

abstract class ImageLoaderService {
  ImageProvider? buildImageProvider(String image);

  Future<LoadedImageInfo?> resolveImageInfo(String image);
}
