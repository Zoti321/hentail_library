import 'package:hentai_library/domain/reading/read_session.dart';

class ReaderRouteArgs {
  const ReaderRouteArgs({
    required this.comicId,
    this.keepControlsOpen = false,
    this.incognito = false,
    this.startFromFirstPage = false,
  });

  static const String readerRouteName = '阅读页面';
  static const String comicIdKey = 'comic_id';
  static const String keepControlsOpenKey = 'keep_controls_open';
  static const String incognitoKey = 'incognito';
  static const String startFromFirstPageKey = 'start_from_first_page';

  final String comicId;
  final bool keepControlsOpen;
  final bool incognito;
  final bool startFromFirstPage;

  ReadSessionRouteParams get session => ReadSessionRouteParams(
    comicId: comicId,
    keepControlsOpen: keepControlsOpen,
    incognito: incognito,
    startFromFirstPage: startFromFirstPage,
  );

  factory ReaderRouteArgs.fromQuery(Map<String, String> queryParameters) {
    final String comicId = (queryParameters[comicIdKey] ?? '').trim();
    final bool keepControlsOpen = queryParameters[keepControlsOpenKey] == '1';
    final bool incognito = queryParameters[incognitoKey] == '1';
    final bool startFromFirstPage =
        queryParameters[startFromFirstPageKey] == '1';
    return ReaderRouteArgs(
      comicId: comicId,
      keepControlsOpen: keepControlsOpen,
      incognito: incognito,
      startFromFirstPage: startFromFirstPage,
    );
  }

  factory ReaderRouteArgs.fromSession(ReadSessionRouteParams session) {
    return ReaderRouteArgs(
      comicId: session.comicId,
      keepControlsOpen: session.keepControlsOpen,
      incognito: session.incognito,
      startFromFirstPage: session.startFromFirstPage,
    );
  }

  Map<String, String> toQueryParameters() {
    final Map<String, String> queryParameters = <String, String>{
      comicIdKey: comicId,
    };
    if (keepControlsOpen) {
      queryParameters[keepControlsOpenKey] = '1';
    }
    if (incognito) {
      queryParameters[incognitoKey] = '1';
    }
    if (startFromFirstPage) {
      queryParameters[startFromFirstPageKey] = '1';
    }
    return queryParameters;
  }
}
