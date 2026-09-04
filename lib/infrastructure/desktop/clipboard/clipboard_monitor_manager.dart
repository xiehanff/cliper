import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:super_clipboard/super_clipboard.dart';

import '../../../application/controllers/app_controller.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/content_type_detector.dart';
import '../../../core/utils/id_generator.dart';
import '../../../domain/entities/clipboard_item.dart';
import '../../../domain/enums/clipboard_item_type.dart';
import '../platform/platform_clipboard.dart';
import 'clipboard_text_reader.dart';

class ClipboardMonitorManager with ClipboardListener {
  static const _readRetryDelays = <Duration>[
    Duration.zero,
    Duration(milliseconds: 25),
    Duration(milliseconds: 75),
  ];

  final AppController _appController;
  final AppLogger _logger;
  final IdGenerator _idGenerator;
  final int Function() _clock;
  bool _started = false;

  ClipboardMonitorManager({
    required AppController appController,
    required AppLogger logger,
    required IdGenerator idGenerator,
    required int Function() clock,
  })  : _appController = appController,
        _logger = logger,
        _idGenerator = idGenerator,
        _clock = clock;

  void start() {
    if (_started) return;
    _started = true;
    clipboardWatcher.addListener(this);
    clipboardWatcher.start();
    _logger.info('Clipboard monitor started');
  }

  void stop() {
    if (!_started) return;
    _started = false;
    clipboardWatcher.removeListener(this);
    clipboardWatcher.stop();
    _logger.info('Clipboard monitor stopped');
  }

  @override
  void onClipboardChanged() {
    _handleClipboardChange();
  }

  Future<void> _handleClipboardChange() async {
    Object? lastError;
    StackTrace? lastStackTrace;

    for (final delay in _readRetryDelays) {
      if (delay != Duration.zero) {
        await Future<void>.delayed(delay);
      }

      try {
        final item = await _readClipboardItem();
        if (item != null) {
          _appController.addClipboardItem(item);
          return;
        }
      } catch (e, stack) {
        lastError = e;
        lastStackTrace = stack;
      }
    }

    if (lastError != null) {
      _logger.error(
        'Failed to handle clipboard change after retries',
        error: lastError,
        stackTrace: lastStackTrace,
      );
    } else {
      _logger.debug('Clipboard change had no supported content');
    }
  }

  Future<ClipboardItem?> _readClipboardItem() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      _logger.warning('System clipboard is not available');
      return null;
    }

    final reader = await clipboard.read();

    final files = await _readFiles(reader);
    if (files.isNotEmpty) {
      return _createItem(ClipboardItemType.file, files: files);
    }

    final text = await ClipboardTextReader.read(reader);
    if (text != null && text.isNotEmpty) {
      final subType = ContentTypeDetector.detect(text);
      return _createItem(subType, text: text);
    }

    final image = await _readImage(reader);
    if (image != null && image.isNotEmpty) {
      return _createItem(ClipboardItemType.image, image: image);
    }

    return null;
  }

  Future<List<String>> _readFiles(ClipboardReader reader) async {
    final paths = <String>[];

    for (final item in reader.items) {
      if (!item.canProvide(Formats.fileUri)) continue;
      final uri = await item.readValue(Formats.fileUri);
      if (uri == null) continue;
      final path = _uriToPath(uri);
      if (path.isNotEmpty) paths.add(path);
    }

    if (paths.isNotEmpty) return paths;

    if (Platform.isWindows) {
      final fallbackPaths = await PlatformClipboard.getFilePaths();
      if (fallbackPaths.isNotEmpty) return fallbackPaths;
    }

    return const [];
  }

  String _uriToPath(Uri uri) {
    try {
      if (uri.scheme == 'file') {
        var path = Uri.decodeComponent(uri.path);
        if (Platform.isWindows && path.startsWith('/')) {
          path = path.substring(1);
        }
        return path;
      }
      return Uri.decodeComponent(uri.toString());
    } catch (e) {
      return uri.toString();
    }
  }

  Future<String?> _readImage(ClipboardReader reader) async {
    if (!reader.canProvide(Formats.png)) return null;

    final completer = Completer<Uint8List?>();
    final progress = reader.getFile(
      Formats.png,
      (file) async {
        try {
          final bytes = await file.readAll();
          completer.complete(bytes);
        } catch (e) {
          completer.complete(null);
        }
      },
      onError: (error) => completer.complete(null),
    );
    if (progress == null) return null;

    final bytes = await completer.future;
    if (bytes == null || bytes.isEmpty) return null;
    return 'data:image/png;base64,${base64Encode(bytes)}';
  }

  ClipboardItem _createItem(
    ClipboardItemType type, {
    String text = '',
    String image = '',
    List<String> files = const [],
  }) {
    return ClipboardItem(
      id: _idGenerator.generate(),
      type: type,
      text: text,
      image: image,
      files: files,
      timestamp: _clock(),
    );
  }
}
