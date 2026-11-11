/// 导航器契约：模块只下达导航意图，宿主应用（go_router）负责执行。
///
/// 纯 Dart，无 Flutter / go_router 依赖。实现由 bootstrap 经
/// `appNavigatorProvider` 注入；feature / shared UI 禁止直接依赖 GoRouter。
abstract class AppNavigator {
  // ---- location facts ----

  /// 当前完整 location（含 query）。
  String currentLocation();

  /// 当前 path（不含 query）。
  String currentPath();

  String? queryParameter(String key);

  bool canPop();

  // ---- top-level intents ----

  void goHome();

  void goLibrary(String libraryId);

  void goMetadata({String? tab});

  void pushMetadata({String? tab});

  /// 仅替换当前 location 的 `tab` query（保留底层栈）。
  void replaceMetadataTab(String tab);

  void goHistory();

  void pushHistory();

  void goTrash();

  void pushTrash();

  void goSettings();

  // ---- detail intents ----

  void goComicDetail(String comicId);

  void goSeriesDetail(String seriesId);

  void pushComicDetail(String comicId);

  void pushSeriesDetail(String seriesId);

  void pushAuthorDetail(int authorId);

  /// 详情内同级切卷：替换当前详情页，保留底层栈。
  void replaceComicDetail(String comicId, {bool reverse = false});

  // ---- reader intents ----

  void openReader({
    required String comicId,
    bool incognito = false,
    bool keepControlsOpen = false,
    bool startFromFirstPage = false,
  });

  void replaceReader({
    required String comicId,
    bool incognito = false,
    bool keepControlsOpen = false,
    bool startFromFirstPage = false,
  });

  // ---- stack ----

  /// owner 解析出的落地 location（如详情返回来源系列）；shared UI 不解析语义。
  void goLocation(String location);

  /// 替换当前 location（阅读器系列切卷等，保留底层栈）。
  void replaceLocation(String location);

  void pop();
}
