import 'dart:io';

import '../../../core/utils/app_logger.dart';

class SingleInstanceLock {
  final AppLogger _logger;
  final String _lockFilePath;
  RandomAccessFile? _handle;

  SingleInstanceLock({
    required AppLogger logger,
    String? lockFilePath,
  })  : _logger = logger,
        _lockFilePath = lockFilePath ??
            '${Directory.systemTemp.path}${Platform.pathSeparator}cliper.lock';

  Future<bool> acquire() async {
    if (_handle != null) return true;

    try {
      final file = File(_lockFilePath);
      final handle = await file.open(mode: FileMode.write);
      try {
        await handle.lock(FileLock.exclusive);
      } catch (e) {
        _logger.info('Another Cliper instance is already running');
        _logger.debug('Failed to acquire single instance lock: $e');
        await handle.close();
        return false;
      }

      _handle = handle;
      _logger.info('Single instance lock acquired');
      return true;
    } catch (e, stack) {
      _logger.error('Failed to acquire single instance lock',
          error: e, stackTrace: stack);
      return false;
    }
  }

  Future<void> release() async {
    final handle = _handle;
    if (handle == null) return;

    _handle = null;
    try {
      await handle.unlock();
    } catch (e) {
      _logger.debug('Failed to release single instance lock: $e');
    } finally {
      try {
        await handle.close();
      } catch (_) {}
    }
  }
}
