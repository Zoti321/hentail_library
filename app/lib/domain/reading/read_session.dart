/// Series read 与 Standalone read 的路由与会话参数。
enum ReadSessionMode { standalone, series }

class ReadSessionRouteParams {
  const ReadSessionRouteParams({
    required this.comicId,
    this.seriesId,
    this.keepControlsOpen = false,
    this.incognito = false,
  });

  final String comicId;
  final String? seriesId;
  final bool keepControlsOpen;
  final bool incognito;

  ReadSessionMode get mode => seriesId != null && seriesId!.isNotEmpty
      ? ReadSessionMode.series
      : ReadSessionMode.standalone;

  bool get isSeriesRead => mode == ReadSessionMode.series;
}
