import 'package:hentai_library/domain/reading/read_session.dart';

class ReaderRouteArgs {
  const ReaderRouteArgs({
    required this.comicId,
    this.seriesId,
    this.keepControlsOpen = false,
    this.incognito = false,
  });

  static const String readerRouteName = '阅读页面';
  static const String comicIdKey = 'comic_id';
  static const String seriesIdKey = 'series_id';
  static const String keepControlsOpenKey = 'keep_controls_open';
  static const String incognitoKey = 'incognito';

  final String comicId;
  final String? seriesId;
  final bool keepControlsOpen;
  final bool incognito;

  ReadSessionRouteParams get session => ReadSessionRouteParams(
    comicId: comicId,
    seriesId: seriesId,
    keepControlsOpen: keepControlsOpen,
    incognito: incognito,
  );

  factory ReaderRouteArgs.fromQuery(Map<String, String> queryParameters) {
    final String comicId = (queryParameters[comicIdKey] ?? '').trim();
    final String? seriesId = _optionalQueryValue(queryParameters[seriesIdKey]);
    final bool keepControlsOpen = queryParameters[keepControlsOpenKey] == '1';
    final bool incognito = queryParameters[incognitoKey] == '1';
    return ReaderRouteArgs(
      comicId: comicId,
      seriesId: seriesId,
      keepControlsOpen: keepControlsOpen,
      incognito: incognito,
    );
  }

  factory ReaderRouteArgs.fromSession(ReadSessionRouteParams session) {
    return ReaderRouteArgs(
      comicId: session.comicId,
      seriesId: session.seriesId,
      keepControlsOpen: session.keepControlsOpen,
      incognito: session.incognito,
    );
  }

  Map<String, String> toQueryParameters() {
    final Map<String, String> queryParameters = <String, String>{
      comicIdKey: comicId,
    };
    final String? resolvedSeriesId = seriesId?.trim();
    if (resolvedSeriesId != null && resolvedSeriesId.isNotEmpty) {
      queryParameters[seriesIdKey] = resolvedSeriesId;
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

String? _optionalQueryValue(String? raw) {
  final String trimmed = raw?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}
