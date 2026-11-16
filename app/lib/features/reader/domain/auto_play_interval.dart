import 'package:hentai_library/features/app_settings/public/reading_preferences_schema.dart';

/// 阅读器自动播放间隔（秒）的取值范围。
///
/// 真源是持久化 schema（`app_settings`，ADR-0046）；此处只做本模块别名。
const int kReaderAutoPlayIntervalMin =
    ReadingPreferenceSchema.minAutoPlayIntervalSeconds;
const int kReaderAutoPlayIntervalMax =
    ReadingPreferenceSchema.maxAutoPlayIntervalSeconds;

/// 默认间隔（秒）。
const int kReaderAutoPlayIntervalDefault =
    ReadingPreferenceSchema.defaultAutoPlayIntervalSeconds;

/// 将间隔限制在 [kReaderAutoPlayIntervalMin, kReaderAutoPlayIntervalMax] 内。
int clampReaderAutoPlayInterval(int seconds) =>
    ReadingPreferenceSchema.clampAutoPlayIntervalSeconds(seconds);

/// 自动翻页开启时底栏 wavy slider 的波长（逻辑像素）。
///
/// 间隔越短波越密；默认 5s → 40（对齐 M3E `SliderTokens.wavelength`）。
double readerAutoPlaySliderWavelength(int intervalSeconds) {
  final int seconds = clampReaderAutoPlayInterval(intervalSeconds);
  return (seconds * 8.0).clamp(16.0, 96.0);
}
