import 'package:flutter/material.dart';
import 'package:hentai_library/features/library_browse/presentation/comic_delete_flow.dart';
import 'package:hentai_library/shared/di/read_session_launch_providers.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Feature-side host for [ComicCard] context-menu commands (keeps shared card pure).
abstract final class ComicCardHost {
  static Future<void> openReader(WidgetRef ref, String comicId) {
    return ref.read(readSessionLaunchPortProvider).openComic(comicId: comicId);
  }

  static void confirmTrash(BuildContext context, WidgetRef ref, Comic comic) {
    confirmAndTrashComic(context, ref, comic);
  }
}
