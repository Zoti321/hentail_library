import 'package:hentai_library/features/read_session/public/reading_preference_types.dart';

/// 阅读器相关设置的写入命令端口（#265）。
///
/// 实现位于 `features/app_settings/di/shared_state_ports.dart`，由 bootstrap 通过 `shared/di` 注入。
abstract class ReaderSettingsCommandPort {
  Future<void> setReadingMode(ReadingMode value);

  Future<void> setWebtoonMarginPercent(int value);

  Future<void> setWebtoonZoomMode(WebtoonZoomMode value);

  Future<void> setReaderAutoPlayIntervalSeconds(int value);

  Future<void> setAutoPlayMode(AutoPlayMode value);
}
