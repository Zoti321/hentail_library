class ReaderRouteArgs {
  const ReaderRouteArgs({
    required this.comicId,
    required this.readType,
    this.seriesId,
    this.keepControlsOpen = false,
    this.incognito = false,
  });

  static const String readerRouteName = '阅读页面';
  static const String readTypeSeries = 'series';
  static const String readTypeComic = 'comic';
  static const String readTypeKey = 'read_type';
  static const String comicIdKey = 'comic_id';
  static const String seriesIdKey = 'series_id';
  static const String keepControlsOpenKey = 'keep_controls_open';
  static const String incognitoKey = 'incognito';
  final String comicId;
  final String readType;
  final String? seriesId;
  final bool keepControlsOpen;
  final bool incognito;
  bool get isSeriesMode => readType == readTypeSeries;

  factory ReaderRouteArgs.fromQuery(Map<String, String> queryParameters) {
    final String comicId = (queryParameters[comicIdKey] ?? '').trim();
    final String normalizedReadType =
        queryParameters[readTypeKey] == readTypeSeries
        ? readTypeSeries
        : readTypeComic;
    final String? rawSeriesId = queryParameters[seriesIdKey];
    final String? normalizedSeriesId =
        rawSeriesId != null && rawSeriesId.isNotEmpty ? rawSeriesId : null;
    final bool isValidSeries =
        normalizedReadType == readTypeSeries && normalizedSeriesId != null;
    final bool keepControlsOpen = queryParameters[keepControlsOpenKey] == '1';
    final bool incognito = queryParameters[incognitoKey] == '1';
    return ReaderRouteArgs(
      comicId: comicId,
      readType: isValidSeries ? readTypeSeries : readTypeComic,
      seriesId: isValidSeries ? normalizedSeriesId : null,
      keepControlsOpen: keepControlsOpen,
      incognito: incognito,
    );
  }

  Map<String, String> toQueryParameters() {
    final Map<String, String> queryParameters = <String, String>{
      readTypeKey: readType,
      comicIdKey: comicId,
    };
    if (isSeriesMode && seriesId != null) {
      queryParameters[seriesIdKey] = seriesId!;
    }
    if (keepControlsOpen) {
      queryParameters[keepControlsOpenKey] = '1';
    }
    if (incognito) {
      queryParameters[incognitoKey] = '1';
    }
    return queryParameters;
  }
}
