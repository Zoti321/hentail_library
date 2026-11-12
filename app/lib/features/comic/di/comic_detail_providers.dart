import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show FutureProviderFamily;

import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/features/comic/di/comic_repository_providers.dart';

Never _missing(String name) =>
    throw UnimplementedError('$name 未注入，请在 bootstrap 中 override');

/// 详情实体：随库 revision 失效，由 bootstrap 以 `overrideWith` 填实。
final FutureProviderFamily<int, String> comicResolvedPageCountProvider =
    FutureProvider.family<int, String>(
      (Ref ref, String comicId) => _missing('comicResolvedPageCountProvider'),
    );

/// 漫画详情实体（owner 本地实现，壳单向 watch）。
final FutureProviderFamily<Comic?, String> comicDetailProvider =
    FutureProvider.family<Comic?, String>((Ref ref, String comicId) {
      ref.watch(
        libraryRevisionStateProvider.select(
          (LibraryRevisionState s) => s.revision,
        ),
      );
      return ref.read(comicLookupRepositoryProvider).findById(comicId);
    });

/// 批量编辑按 id 载入实体。
final FutureProviderFamily<List<Comic>, List<String>>
bulkEditComicsByIdsProvider = FutureProvider.family<List<Comic>, List<String>>((
  Ref ref,
  List<String> comicIds,
) {
  ref.watch(
    libraryRevisionStateProvider.select((LibraryRevisionState s) => s.revision),
  );
  return ref.read(comicLookupRepositoryProvider).findByIds(comicIds);
});
