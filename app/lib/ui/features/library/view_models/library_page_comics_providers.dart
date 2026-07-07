import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/ui/features/library/view_models/library_comics_catalog_controller.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_catalog_controller.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_page_comics_providers.g.dart';

/// Action 门面：刷新变更通知并重置到第一页。
final Provider<VoidCallback> libraryRefreshActionProvider =
    Provider<VoidCallback>((Ref ref) {
      return () {
        ref.read(libraryComicsCatalogControllerProvider.notifier).refresh();
        ref.read(librarySeriesCatalogControllerProvider.notifier).refresh();
      };
    });

@Riverpod(keepAlive: true)
Future<Comic?> libraryComicDetail(Ref ref, String comicId) {
  ref.watch(
    libraryRevisionProvider.select((LibraryRevisionState s) => s.revision),
  );
  return ref.read(comicRepoProvider).findById(comicId);
}
