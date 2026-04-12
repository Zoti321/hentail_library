class ReaderRouteArgs {
  const ReaderRouteArgs({
    required this.comicId,
    required this.readType,
    this.seriesName,
  });

  static const String readerRouteName = '阅读页面';
  static const String readTypeSeries = 'series';
  static const String readTypeComic = 'comic';
  static const String readTypeKey = 'read_type';
  static const String comicIdKey = 'comic_id';
  static const String seriesNameKey = 'series_name';
  final String comicId;
  final String readType;
  final String? seriesName;
  bool get isSeriesMode => readType == readTypeSeries;

  factory ReaderRouteArgs.fromQuery(Map<String, String> queryParameters) {
    final String comicId = (queryParameters[comicIdKey] ?? '').trim();
    final String normalizedReadType =
        queryParameters[readTypeKey] == readTypeSeries
        ? readTypeSeries
        : readTypeComic;
    final String? rawSeriesName = queryParameters[seriesNameKey];
    final String? normalizedSeriesName =
        rawSeriesName != null && rawSeriesName.isNotEmpty
        ? rawSeriesName
        : null;
    final bool isValidSeries =
        normalizedReadType == readTypeSeries && normalizedSeriesName != null;
    return ReaderRouteArgs(
      comicId: comicId,
      readType: isValidSeries ? readTypeSeries : readTypeComic,
      seriesName: isValidSeries ? normalizedSeriesName : null,
    );
  }
  Map<String, String> toQueryParameters() {
    final Map<String, String> queryParameters = <String, String>{
      readTypeKey: readType,
      comicIdKey: comicId,
    };
    if (isSeriesMode && seriesName != null) {
      queryParameters[seriesNameKey] = seriesName!;
    }
    return queryParameters;
  }
}
