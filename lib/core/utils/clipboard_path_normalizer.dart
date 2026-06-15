import 'dart:io';

import 'package:path/path.dart' as path;

final _windowsPathContext = path.Context(style: path.Style.windows);

String normalizeClipboardFilePath(String value) {
  if (value.isEmpty || !Platform.isWindows) return value;

  try {
    return _windowsPathContext.normalize(value).toLowerCase();
  } catch (_) {
    return value.toLowerCase();
  }
}

