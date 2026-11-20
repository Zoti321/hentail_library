/// 集中式路由表：location / GoRoute.name / path 谓词的唯一来源。
///
/// 只含纯 Dart 常量与字符串构造，不依赖 Flutter / go_router；
/// feature 只 import 本表或 [AppNavigator]，不再拼裸路径。
abstract final class AppRoutes {
  // ---- paths ----

  static const String home = '/home';
  static const String media = '/media';
  static const String mediaName = '媒体';
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
  static const String imageSetSegment = 'image-sets';
  static const String imageSetReaderSegment = 'reader';

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
  static const String imageSetDetailName = '图集详情';
  static const String imageSetReaderName = '图集阅读';
  static const String seriesDetailName = '系列详情';
  static const String authorDetailName = '作者详情';
  static const String readerName = '阅读页面';
  static const String notFoundName = '页面不存在';

  // ---- builders ----

  static String library(String libraryId) =>
      '$libraries/${Uri.encodeComponent(libraryId)}';

  static String imageSetDetail(String libraryId, String imageSetId) =>
      '${library(libraryId)}/$imageSetSegment/${Uri.encodeComponent(imageSetId)}';

  static String imageSetReaderLocation({
    required String libraryId,
    required String imageSetId,
    required Map<String, String> queryParameters,
  }) =>
      Uri(
        path:
            '${library(libraryId)}/$imageSetSegment/${Uri.encodeComponent(imageSetId)}/$imageSetReaderSegment',
        queryParameters: queryParameters,
      ).toString();

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

  static bool isImageSetLibraryPath(String path) {
    if (!path.startsWith('$libraries/')) {
      return false;
    }
    final String rest = path.substring('$libraries/'.length);
    if (rest.isEmpty || rest.startsWith('$legacyAllSegment/')) {
      return false;
    }
    final List<String> segments = rest.split('/');
    return segments.length >= 2 &&
        segments[1] == imageSetSegment &&
        segments[0] != legacyAllSegment;
  }

  static bool isImageSetDetailPath(String path) {
    if (!isImageSetLibraryPath(path)) {
      return false;
    }
    final List<String> segments = _libraryPathSegments(path);
    return segments.length == 3;
  }

  static bool isImageSetReaderPath(String path) {
    if (!isImageSetLibraryPath(path)) {
      return false;
    }
    final List<String> segments = _libraryPathSegments(path);
    return segments.length >= 4 && segments[3] == imageSetReaderSegment;
  }

  static bool isSeriesDetailPath(String path) =>
      path.startsWith('/$seriesSegment/');

  static bool isCatalogDetailPath(String path) =>
      isComicDetailPath(path) ||
      isSeriesDetailPath(path) ||
      isImageSetDetailPath(path);

  static String? libraryIdFromPath(String path) {
    const String prefix = '$libraries/';
    if (!path.startsWith(prefix)) {
      return null;
    }
    final String rest = path.substring(prefix.length);
    if (rest.isEmpty) {
      return null;
    }
    final int slash = rest.indexOf('/');
    final String id = slash < 0 ? rest : rest.substring(0, slash);
    if (id.isEmpty || id == legacyAllSegment) {
      return null;
    }
    return Uri.decodeComponent(id);
  }

  static List<String> _libraryPathSegments(String path) {
    const String prefix = '$libraries/';
    final String rest = path.substring(prefix.length);
    return rest
        .split('/')
        .where((String s) => s.isNotEmpty)
        .map(Uri.decodeComponent)
        .toList();
  }

  /// 旧深链（`/local`、裸 `/libraries`、`/libraries/all`）统一回 Home。
  static String? legacyRedirectPath(String path) {
    if (path == local || path == libraries || path == legacyAll) {
      return home;
    }
    return null;
  }
}
