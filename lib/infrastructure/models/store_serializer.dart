import 'dart:convert';

import '../../core/utils/app_logger.dart';
import '../../domain/entities/clipboard_store.dart';

class StoreSerializer {
  final AppLogger _logger;

  const StoreSerializer({required AppLogger logger}) : _logger = logger;

  String encode(ClipboardStore store) {
    return const JsonEncoder.withIndent('  ').convert(store.toJson());
  }

  ClipboardStore decode(String raw) {
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is List) {
        _logger
            .info('Detected legacy array store format, treating as realtime');
        return ClipboardStore.fromJson({'realtime': decoded});
      }
      if (decoded is Map<String, dynamic>) {
        return ClipboardStore.fromJson(decoded);
      }
      _logger.warning('Unexpected store root type: ${decoded.runtimeType}');
      return const ClipboardStore();
    } on FormatException catch (e, stack) {
      _logger.error('Store JSON corrupted, falling back to default',
          error: e, stackTrace: stack);
      return const ClipboardStore();
    } catch (e, stack) {
      _logger.error('Failed to decode store, falling back to default',
          error: e, stackTrace: stack);
      return const ClipboardStore();
    }
  }
}
