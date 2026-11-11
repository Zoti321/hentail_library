import 'package:flutter/material.dart';
import 'package:hentai_library/features/comic/presentation/comic_delete_flow.dart';
import 'package:hentai_library/shared/di/reader_launch_providers.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Feature-side host for [ComicCard] context-menu commands (keeps shared card pure).
abstract final class ComicCardHost {
  static Future<void> openReader(WidgetRef ref, String comicId) {
    return ref.read(readerLaunchPortProvider).openComic(comicId: comicId);
  }

  static void confirmTrash(BuildContext context, WidgetRef ref, Comic comic) {
    confirmAndTrashComic(context, ref, comic);
  }

  static void confirmTrashById(
    BuildContext context,
    WidgetRef ref, {
    required String comicId,
    required String title,
  }) {
    confirmAndTrashComicById(context, ref, comicId: comicId, title: title);
  }
}
