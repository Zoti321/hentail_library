class ReaderRouteArgs {
  const ReaderRouteArgs({
    required this.comicId,
    this.keepControlsOpen = false,
    this.incognito = false,
  });

  static const String readerRouteName = '阅读页面';
  static const String comicIdKey = 'comic_id';
  static const String keepControlsOpenKey = 'keep_controls_open';
  static const String incognitoKey = 'incognito';

  final String comicId;
  final bool keepControlsOpen;
  final bool incognito;

  factory ReaderRouteArgs.fromQuery(Map<String, String> queryParameters) {
    final String comicId = (queryParameters[comicIdKey] ?? '').trim();
    final bool keepControlsOpen = queryParameters[keepControlsOpenKey] == '1';
    final bool incognito = queryParameters[incognitoKey] == '1';
    return ReaderRouteArgs(
      comicId: comicId,
      keepControlsOpen: keepControlsOpen,
      incognito: incognito,
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
    return queryParameters;
  }
}
