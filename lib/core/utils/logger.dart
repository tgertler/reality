import 'package:logger/logger.dart';

class CustomPrinter extends LogPrinter {
  final String className;

  CustomPrinter(this.className);

  @override
  List<String> log(LogEvent event) {
    final message = event.message;
    final error = event.error;
    final stackTrace = event.stackTrace;
    final level = _getLevelAbbreviation(event.level);
    final time = DateTime.now().toIso8601String();
    final logMessages = ['[$time] [$level] [$className] : $message'];

    if (error != null) {
      logMessages.add('[$time] [$level] [$className] : Error: $error');
    }

    if (stackTrace != null) {
      logMessages.add('[$time] [$level] [$className] : Stacktrace: $stackTrace');
    }

    return logMessages;
  }

  String _getLevelAbbreviation(Level level) {
    switch (level) {
      case Level.verbose:
        return 'V';
      case Level.debug:
        return 'D';
      case Level.info:
        return 'I';
      case Level.warning:
        return 'W';
      case Level.error:
        return 'E';
      case Level.wtf:
        return 'F';
      default:
        return 'U'; // Unknown
    }
  }
}

Logger getLogger(String className) {
  return Logger(
    printer: CustomPrinter(className),
  );
}

final Logger logger = getLogger('AppLogger');