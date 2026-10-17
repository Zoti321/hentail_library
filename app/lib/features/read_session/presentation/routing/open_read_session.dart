import 'package:hentai_library/shared/di/read_session_launch_providers.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> openReadSession(
  WidgetRef ref, {
  required String comicId,
  bool incognito = false,
  bool keepControlsOpen = false,
  bool startFromFirstPage = false,
}) {
  return ref
      .read(readSessionLaunchPortProvider)
      .openComic(
        comicId: comicId,
        incognito: incognito,
        keepControlsOpen: keepControlsOpen,
        startFromFirstPage: startFromFirstPage,
      );
}

Future<void> openComicReadSession(
  WidgetRef ref, {
  required Comic comic,
  bool incognito = false,
}) {
  return openReadSession(ref, comicId: comic.comicId, incognito: incognito);
}
