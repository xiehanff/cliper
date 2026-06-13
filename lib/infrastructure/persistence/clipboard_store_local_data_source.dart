import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/clipboard_store.dart';
import '../../domain/repositories/store_repository.dart';
import '../models/store_serializer.dart';

class ClipboardStoreLocalDataSource implements StoreRepository {
  final StoreSerializer _serializer;
  final AppLogger _logger;
  final Future<Directory> Function()? _directoryProvider;

  ClipboardStoreLocalDataSource({
    required StoreSerializer serializer,
    required AppLogger logger,
    Future<Directory> Function()? directoryProvider,
  })  : _serializer = serializer,
        _logger = logger,
        _directoryProvider = directoryProvider;

  Future<Directory> get _storageDirectory async {
    if (_directoryProvider != null) return _directoryProvider();
    return getApplicationSupportDirectory();
  }

  Future<File> get _storeFile async {
    final dir = await _storageDirectory;
    return File(path.join(dir.path, AppConstants.storeFileName));
  }

  @override
  Future<ClipboardStore> load() async {
    try {
      final file = await _storeFile;
      if (!await file.exists()) {
        _logger.info('Store file not found, using default store');
        return const ClipboardStore();
      }
      final raw = await file.readAsString();
      return _serializer.decode(raw);
    } catch (e, stack) {
      _logger.error('Failed to load store, using default',
          error: e, stackTrace: stack);
      return const ClipboardStore();
    }
  }

  @override
  Future<void> save(ClipboardStore store) async {
    try {
      final file = await _storeFile;
      final parent = file.parent;
      if (!await parent.exists()) {
        await parent.create(recursive: true);
      }
      final raw = _serializer.encode(store);
      await file.writeAsString(raw, flush: true);
    } catch (e, stack) {
      _logger.error('Failed to save store', error: e, stackTrace: stack);
    }
  }
}
