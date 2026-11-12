/// 集中式路由表：location / GoRoute.name / path 谓词的唯一来源。
///
/// 只含纯 Dart 常量与字符串构造，不依赖 Flutter / go_router；
/// feature 只 import 本表或 [AppNavigator]，不再拼裸路径。
abstract final class AppRoutes {
  // ---- paths ----

  static const String home = '/home';
  static const String local = '/local';
  static const String history = '/history';
  static const String trash = '/trash';
  static const String settings = '/settings';
  static const String metadata = '/metadata';
  static const String libraries = '/libraries';
  static const String reader = '/reader';

  static const String comicSegment = 'comic';
  static const String seriesSegment = 'series';
  static const String authorSegment = 'author';

  /// 已退役的聚合浏览段；`/libraries/all` 永不作为真实 Library。
  static const String legacyAllSegment = 'all';
  static const String legacyAll = '$libraries/$legacyAllSegment';

  static const String metadataTabQueryKey = 'tab';

  // ---- GoRoute.name ----

  static const String homeName = '主页';
  static const String libraryName = '漫画库';
  static const String localName = '本地漫画';
  static const String historyName = '历史记录';
  static const String trashName = '已删除';
  static const String settingsName = '设置';
  static const String metadataName = '管理';
  static const String comicDetailName = '漫画详情';
  static const String seriesDetailName = '系列详情';
  static const String authorDetailName = '作者详情';
  static const String readerName = '阅读页面';
  static const String notFoundName = '页面不存在';

  // ---- builders ----

  static String library(String libraryId) =>
      '$libraries/${Uri.encodeComponent(libraryId)}';

  static String comic(String comicId) =>
      '/$comicSegment/${Uri.encodeComponent(comicId)}';

  static String series(String seriesId) =>
      '/$seriesSegment/${Uri.encodeComponent(seriesId)}';

  static String author(int authorId) => '/$authorSegment/$authorId';

  static String metadataTab(String tab) =>
      '$metadata?$metadataTabQueryKey=${Uri.encodeQueryComponent(tab)}';

  static String readerLocation(Map<String, String> queryParameters) =>
      Uri(path: reader, queryParameters: queryParameters).toString();

  // ---- predicates ----

  static bool isReaderPath(String pathOrLocation) {
    final String path = Uri.tryParse(pathOrLocation)?.path ?? pathOrLocation;
    return path == reader || path.startsWith('$reader/');
  }

  static bool isComicDetailPath(String path) =>
      path.startsWith('/$comicSegment/');

  static bool isSeriesDetailPath(String path) =>
      path.startsWith('/$seriesSegment/');

  static bool isCatalogDetailPath(String path) =>
      isComicDetailPath(path) || isSeriesDetailPath(path);

  static String? libraryIdFromPath(String path) {
    const String prefix = '$libraries/';
    if (!path.startsWith(prefix)) {
      return null;
    }
    final String id = path.substring(prefix.length);
    if (id.isEmpty || id.contains('/') || id == legacyAllSegment) {
      return null;
    }
    return id;
  }

  /// 旧深链（`/local`、裸 `/libraries`、`/libraries/all`）统一回 Home。
  static String? legacyRedirectPath(String path) {
    if (path == local || path == libraries || path == legacyAll) {
      return home;
    }
    return null;
  }
}
