/// 阅读器自动播放间隔（秒）的取值范围，设置存储与设置面板共用。
const int kReaderAutoPlayIntervalMin = 1;
const int kReaderAutoPlayIntervalMax = 60;

/// 将间隔限制在 [kReaderAutoPlayIntervalMin, kReaderAutoPlayIntervalMax] 内。
int clampReaderAutoPlayInterval(int seconds) =>
    seconds.clamp(kReaderAutoPlayIntervalMin, kReaderAutoPlayIntervalMax);
