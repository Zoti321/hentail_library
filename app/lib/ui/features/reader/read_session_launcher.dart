import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/reading/read_session.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';
import 'package:hentai_library/ui/features/shell/views/routing/reader_route_args.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 打开阅读器；系列上下文由 comicId 在阅读器内派生（ADR-0005）。
Future<void> openReadSession(
  WidgetRef ref, {
  required String comicId,
  bool incognito = false,
  bool keepControlsOpen = false,
  bool startFromFirstPage = false,
}) async {
  final ReadSessionRouteParams session = ReadSessionRouteParams(
    comicId: comicId,
    incognito: incognito,
    keepControlsOpen: keepControlsOpen,
    startFromFirstPage: startFromFirstPage,
  );
  appRouter.pushNamed(
    ReaderRouteArgs.readerRouteName,
    queryParameters: ReaderRouteArgs.fromSession(session).toQueryParameters(),
  );
}

Future<void> openComicReadSession(
  WidgetRef ref, {
  required Comic comic,
  bool incognito = false,
}) async {
  await openReadSession(ref, comicId: comic.comicId, incognito: incognito);
}
