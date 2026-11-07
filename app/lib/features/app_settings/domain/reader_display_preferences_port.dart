import 'package:hentai_library/features/app_settings/domain/reader_session_preference_types.dart';

/// 阅读器展示相关设置的只读端口（webtoon 边距/缩放等，#441）。
abstract class ReaderDisplayPreferencesPort {
  int get webtoonMarginPercent;

  WebtoonZoomMode get webtoonZoomMode;
}
