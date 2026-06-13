import 'dart:io';

import 'package:launch_at_startup/launch_at_startup.dart';

import '../../../core/utils/app_logger.dart';
import '../../../domain/services/launch_at_startup_service.dart';

class LaunchAtStartupServiceImpl implements LaunchAtStartupService {
  final AppLogger _logger;
  bool _setup = false;

  LaunchAtStartupServiceImpl({required AppLogger logger}) : _logger = logger;

  Future<void> _ensureSetup() async {
    if (_setup) return;
    _setup = true;
    launchAtStartup.setup(
      appName: 'Cliper',
      appPath: Platform.resolvedExecutable,
    );
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    try {
      await _ensureSetup();
      if (enabled) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
      _logger.info('Launch at startup set to $enabled');
    } catch (e, stack) {
      _logger.error('Failed to set launch at startup',
          error: e, stackTrace: stack);
    }
  }
}
