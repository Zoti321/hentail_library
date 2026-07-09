import 'package:logging/logging.dart';

/// 按架构层命名的 Logger 工厂（见 ADR-0003）。
abstract final class AppLog {
  static Logger dataRepo(String name) => Logger('hentai.data.repo.$name');

  static Logger dataFrb() => Logger('hentai.data.frb');

  static Logger ui(String name) => Logger('hentai.ui.$name');

  static Logger core(String name) => Logger('hentai.core.$name');
}

void logError(
  Logger logger,
  String message,
  Object error,
  StackTrace stackTrace,
) {
  logger.log(Level.SEVERE, message, error, stackTrace);
}
