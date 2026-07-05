import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/reading/read_session.dart';
import 'package:hentai_library/ui/features/reader/view_models/series_reader_provider.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';
import 'package:hentai_library/ui/features/shell/views/routing/reader_route_args.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 打开阅读器；Series read 需传入 [seriesId]。
Future<void> openReadSession(
  WidgetRef ref, {
  required String comicId,
  String? seriesId,
  bool incognito = false,
  bool keepControlsOpen = false,
}) async {
  final ReadSessionRouteParams session = ReadSessionRouteParams(
    comicId: comicId,
    seriesId: seriesId,
    incognito: incognito,
    keepControlsOpen: keepControlsOpen,
  );
  appRouter.pushNamed(
    ReaderRouteArgs.readerRouteName,
    queryParameters: ReaderRouteArgs.fromSession(session).toQueryParameters(),
  );
}

Future<void> openSeriesReadSession(
  WidgetRef ref, {
  required String seriesId,
  bool incognito = false,
}) async {
  final String comicId = await ref.read(
    resolveSeriesReadComicIdProvider(seriesId: seriesId).future,
  );
  if (comicId.isEmpty) {
    return;
  }
  await openReadSession(
    ref,
    comicId: comicId,
    seriesId: seriesId,
    incognito: incognito,
  );
}

Future<void> openComicReadSession(
  WidgetRef ref, {
  required Comic comic,
  bool incognito = false,
}) async {
  final String? seriesId = incognito
      ? null
      : await ref.read(
          resolveSeriesIdForComicReadProvider(comicId: comic.comicId).future,
        );
  await openReadSession(
    ref,
    comicId: comic.comicId,
    seriesId: seriesId,
    incognito: incognito,
  );
}
