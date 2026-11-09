import 'package:hentai_library/shared/di/reader_launch_providers.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> openReader(
  WidgetRef ref, {
  required String comicId,
  bool incognito = false,
  bool keepControlsOpen = false,
  bool startFromFirstPage = false,
}) {
  return ref
      .read(readerLaunchPortProvider)
      .openComic(
        comicId: comicId,
        incognito: incognito,
        keepControlsOpen: keepControlsOpen,
        startFromFirstPage: startFromFirstPage,
      );
}

Future<void> openComicInReader(
  WidgetRef ref, {
  required Comic comic,
  bool incognito = false,
}) {
  return openReader(ref, comicId: comic.comicId, incognito: incognito);
}
