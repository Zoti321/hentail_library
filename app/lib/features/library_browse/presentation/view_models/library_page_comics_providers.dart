import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/features/library_browse/presentation/library.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/domain/library/library_revision_state.dart';
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
    libraryRevisionStateProvider.select((LibraryRevisionState s) => s.revision),
  );
  return ref.read(comicLookupRepositoryProvider).findById(comicId);
}

@Riverpod(keepAlive: true)
Future<List<Comic>> bulkEditComicsByIds(Ref ref, List<String> comicIds) {
  ref.watch(
    libraryRevisionStateProvider.select((LibraryRevisionState s) => s.revision),
  );
  return ref.read(comicLookupRepositoryProvider).findByIds(comicIds);
}
