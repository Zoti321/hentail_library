/// 阅读器自动播放间隔（秒）的取值范围，设置存储与设置面板共用。
const int kReaderAutoPlayIntervalMin = 1;
const int kReaderAutoPlayIntervalMax = 60;

/// 默认间隔（秒）；与 [AppSetting.readerAutoPlayIntervalSeconds] 默认值对齐。
const int kReaderAutoPlayIntervalDefault = 5;

/// 将间隔限制在 [kReaderAutoPlayIntervalMin, kReaderAutoPlayIntervalMax] 内。
int clampReaderAutoPlayInterval(int seconds) =>
    seconds.clamp(kReaderAutoPlayIntervalMin, kReaderAutoPlayIntervalMax);

/// 自动翻页开启时底栏 wavy slider 的波长（逻辑像素）。
///
/// 间隔越短波越密；默认 5s → 40（对齐 M3E `SliderTokens.wavelength`）。
double readerAutoPlaySliderWavelength(int intervalSeconds) {
  final int seconds = clampReaderAutoPlayInterval(intervalSeconds);
  return (seconds * 8.0).clamp(16.0, 96.0);
}
