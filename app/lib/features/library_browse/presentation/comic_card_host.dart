import 'package:flutter/material.dart';
import 'package:hentai_library/features/bootstrap/presentation/views/routing/app_router.dart';
import 'package:hentai_library/features/bootstrap/presentation/views/routing/reader_route_args.dart';
import 'package:hentai_library/features/library_browse/presentation/comic_delete_flow.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Feature-side host for [ComicCard] context-menu commands (keeps shared card pure).
abstract final class ComicCardHost {
  static void openReader(String comicId) {
    appRouter.pushNamed(
      ReaderRouteArgs.readerRouteName,
      queryParameters: ReaderRouteArgs(comicId: comicId).toQueryParameters(),
    );
  }

  static void confirmTrash(
    BuildContext context,
    WidgetRef ref,
    Comic comic,
  ) {
    confirmAndTrashComic(context, ref, comic);
  }
}
