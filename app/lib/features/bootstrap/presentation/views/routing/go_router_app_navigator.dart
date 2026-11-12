import 'package:go_router/go_router.dart';
import 'package:hentai_library/core/constants/app_routes.dart';
import 'package:hentai_library/features/reader/public.dart';
import 'package:hentai_library/shared/application/contracts/app_navigator.dart';
import 'package:hentai_library/design-system/design_system.dart';

/// [AppNavigator] 的 go_router 适配器：仅宿主 bootstrap 持有具体路由实现。
class GoRouterAppNavigator implements AppNavigator {
  GoRouterAppNavigator(this._router);

  final GoRouter _router;

  Uri get _uri => _router.routerDelegate.currentConfiguration.uri;

  @override
  String currentLocation() => _uri.toString();

  @override
  String currentPath() => _uri.path;

  @override
  String? queryParameter(String key) => _uri.queryParameters[key];

  @override
  bool canPop() => _router.canPop();

  @override
  void goHome() => _router.go(AppRoutes.home);

  @override
  void goLibrary(String libraryId) => _router.go(AppRoutes.library(libraryId));

  @override
  void goMetadata({String? tab}) =>
      _router.go(tab == null ? AppRoutes.metadata : AppRoutes.metadataTab(tab));

  @override
  void pushMetadata({String? tab}) => _router.push(
    tab == null ? AppRoutes.metadata : AppRoutes.metadataTab(tab),
  );

  @override
  void replaceMetadataTab(String tab) =>
      _router.replace(AppRoutes.metadataTab(tab));

  @override
  void goHistory() => _router.go(AppRoutes.history);

  @override
  void pushHistory() => _router.push(AppRoutes.history);

  @override
  void goTrash() => _router.go(AppRoutes.trash);

  @override
  void pushTrash() => _router.push(AppRoutes.trash);

  @override
  void goSettings() => _router.go(AppRoutes.settings);

  @override
  void goComicDetail(String comicId) => _router.go(AppRoutes.comic(comicId));

  @override
  void goSeriesDetail(String seriesId) =>
      _router.go(AppRoutes.series(seriesId));

  @override
  void pushComicDetail(String comicId) =>
      _router.push(AppRoutes.comic(comicId));

  @override
  void pushSeriesDetail(String seriesId) =>
      _router.push(AppRoutes.series(seriesId));

  @override
  void pushAuthorDetail(int authorId) =>
      _router.push(AppRoutes.author(authorId));

  @override
  void replaceComicDetail(String comicId, {bool reverse = false}) =>
      _router.pushReplacement(
        AppRoutes.comic(comicId),
        extra: CatalogSeriesNavExtra(reverse: reverse),
      );

  @override
  void openReader({
    required String comicId,
    bool incognito = false,
    bool keepControlsOpen = false,
    bool startFromFirstPage = false,
  }) {
    _router.push(
      AppRoutes.readerLocation(
        _readerQuery(
          comicId: comicId,
          incognito: incognito,
          keepControlsOpen: keepControlsOpen,
          startFromFirstPage: startFromFirstPage,
        ),
      ),
    );
  }

  @override
  void replaceReader({
    required String comicId,
    bool incognito = false,
    bool keepControlsOpen = false,
    bool startFromFirstPage = false,
  }) {
    _router.pushReplacement(
      AppRoutes.readerLocation(
        _readerQuery(
          comicId: comicId,
          incognito: incognito,
          keepControlsOpen: keepControlsOpen,
          startFromFirstPage: startFromFirstPage,
        ),
      ),
    );
  }

  @override
  void goLocation(String location) => _router.go(location);

  @override
  void replaceLocation(String location) => _router.pushReplacement(location);

  @override
  void pop() => _router.pop();

  Map<String, String> _readerQuery({
    required String comicId,
    required bool incognito,
    required bool keepControlsOpen,
    required bool startFromFirstPage,
  }) {
    return ReaderRouteArgs(
      comicId: comicId,
      incognito: incognito,
      keepControlsOpen: keepControlsOpen,
      startFromFirstPage: startFromFirstPage,
    ).toQueryParameters();
  }
}
