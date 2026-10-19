import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/shared/domain/ports/reader_settings_command_port.dart';
import 'package:hentai_library/shared/domain/reading/auto_play_mode.dart';
import 'package:hentai_library/shared/domain/reading/reading_mode.dart';

/// app_settings 对阅读器设置写入端口的实现（#265）。
class _ReaderSettingsCommandAdapter implements ReaderSettingsCommandPort {
  _ReaderSettingsCommandAdapter(this._ref);

  final Ref _ref;

  SettingsNotifier get _notifier => _ref.read(settingsProvider.notifier);

  @override
  Future<void> setReadingMode(ReadingMode value) =>
      _notifier.setReadingMode(value);

  @override
  Future<void> setWebtoonMarginPercent(int value) =>
      _notifier.setWebtoonMarginPercent(value);

  @override
  Future<void> setWebtoonZoomMode(WebtoonZoomMode value) =>
      _notifier.setWebtoonZoomMode(value);

  @override
  Future<void> setReaderAutoPlayIntervalSeconds(int value) =>
      _notifier.setReaderAutoPlayIntervalSeconds(value);

  @override
  Future<void> setAutoPlayMode(AutoPlayMode value) =>
      _notifier.setAutoPlayMode(value);
}

/// 适配器工厂：由 bootstrap 通过 `shared/di` 的端口 Provider `overrideWith` 注入。
ReaderSettingsCommandPort createReaderSettingsCommandPort(Ref ref) =>
    _ReaderSettingsCommandAdapter(ref);
