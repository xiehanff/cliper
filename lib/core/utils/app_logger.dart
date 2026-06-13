import 'dart:developer' as developer;

abstract interface class AppLogger {
  void debug(String message);
  void info(String message);
  void warning(String message);
  void error(String message, {Object? error, StackTrace? stackTrace});
}

final class DeveloperAppLogger implements AppLogger {
  const DeveloperAppLogger();

  @override
  void debug(String message) => _log('DEBUG', message);

  @override
  void info(String message) => _log('INFO', message);

  @override
  void warning(String message) => _log('WARN', message);

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      _log('ERROR', message, error: error, stackTrace: stackTrace);

  void _log(
    String level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      '[$level] $message',
      name: 'Cliper',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

class LoggerProvider {
  static AppLogger instance = const DeveloperAppLogger();
}
