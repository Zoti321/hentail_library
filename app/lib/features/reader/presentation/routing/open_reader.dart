import 'package:hentai_library/shared/presentation/providers/app_navigator_provider.dart';
import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> openReader(
  WidgetRef ref, {
  required String comicId,
  bool incognito = false,
  bool keepControlsOpen = false,
  bool startFromFirstPage = false,
}) => Future<void>.sync(() {
  ref
      .read(appNavigatorProvider)
      .openReader(
        comicId: comicId,
        incognito: incognito,
        keepControlsOpen: keepControlsOpen,
        startFromFirstPage: startFromFirstPage,
      );
});

Future<void> openComicInReader(
  WidgetRef ref, {
  required ReaderComicRef comic,
  bool incognito = false,
}) {
  return openReader(ref, comicId: comic.comicId, incognito: incognito);
}
