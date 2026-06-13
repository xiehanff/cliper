import 'dart:io';

import 'package:flutter/services.dart';

class PlatformClipboard {
  static const _channel = MethodChannel('com.example.cliper/clipboard');

  static Future<List<String>> getFilePaths() async {
    if (!Platform.isWindows) return const [];

    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getFilePaths');
      return result?.cast<String>() ?? const [];
    } catch (e) {
      return const [];
    }
  }
}
