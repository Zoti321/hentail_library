import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_facets.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_entry.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_session.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_sync_outcome.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

typedef ImageSetSyncCommand = Future<ImageSetSyncOutcome> Function(
  String libraryId,
);
typedef ImageSetReaderEntryCommand = void Function(ImageSetReaderEntry entry);
typedef ImageSetSetImagesExcludedCommand =
    Future<void> Function(
      String libraryId,
      String imageSetId,
      List<String> imageIds, {
      required bool excluded,
    });
typedef ImageSetReorderImagesCommand =
    Future<void> Function(
      String libraryId,
      String imageSetId,
      List<String> orderedIds,
    );
typedef ImageSetImagesKey = ({String libraryId, String imageSetId});
typedef ImageSetPageBytesKey = ({String libraryId, ImageSetImage image});
typedef ImageSetFacetsQuery = Future<ImageSetFacets> Function(String imageSetId);

/// Image set 目录读取 query（由 composition 绑定 use case）。
final Provider<Future<List<ImageSet>> Function(String libraryId)>
imageSetListQueryProvider = requiredProvider('imageSetListQueryProvider');

final Provider<
  Future<List<ImageSetImage>> Function(String libraryId, String imageSetId)
>
imageSetImagesQueryProvider = requiredProvider('imageSetImagesQueryProvider');

final Provider<
  Future<List<ImageSetImage>> Function(String libraryId, String imageSetId)
>
imageSetWorkspaceImagesQueryProvider = requiredProvider(
  'imageSetWorkspaceImagesQueryProvider',
);

/// Facet bindings query（composition 绑定 use case；不走 Comic metadata）。
final Provider<ImageSetFacetsQuery> imageSetFacetsQueryProvider =
    requiredProvider('imageSetFacetsQueryProvider');

/// 手动同步 command：复用 library_admin 扫描 run 并映射终态。
final Provider<ImageSetSyncCommand> syncImageSetLibraryCommandProvider =
    requiredProvider('syncImageSetLibraryCommandProvider');

/// Read session 打开 query（composition 绑定 use case）。
final Provider<
  Future<ImageSetReaderSession> Function(ImageSetReaderEntry entry)
>
imageSetReaderSessionQueryProvider = requiredProvider(
  'imageSetReaderSessionQueryProvider',
);

/// 单页原始字节 query（composition 绑定 use case）。
final Provider<
  Future<Uint8List> Function(String libraryId, ImageSetImage image)
>
imageSetPageBytesQueryProvider = requiredProvider(
  'imageSetPageBytesQueryProvider',
);

/// 缩略图选中后的 Reader 入口回调（composition 绑定为打开 Image set Reader 页）。
final Provider<ImageSetReaderEntryCommand> imageSetReaderEntryCommandProvider =
    requiredProvider('imageSetReaderEntryCommandProvider');

final Provider<ImageSetSetImagesExcludedCommand>
imageSetSetImagesExcludedCommandProvider = requiredProvider(
  'imageSetSetImagesExcludedCommandProvider',
);

final Provider<ImageSetReorderImagesCommand>
imageSetReorderImagesCommandProvider = requiredProvider(
  'imageSetReorderImagesCommandProvider',
);

/// catalog 变更（sync 成功）后随 library revision 重新读取。
final imageSetSetsProvider = FutureProvider.autoDispose
    .family<List<ImageSet>, String>((Ref ref, String libraryId) {
      ref.watch(libraryRevisionStateProvider.select((s) => s.revision));
      return ref.watch(imageSetListQueryProvider)(libraryId);
    });

final imageSetImagesProvider = FutureProvider.autoDispose
    .family<List<ImageSetImage>, ImageSetImagesKey>((
      Ref ref,
      ImageSetImagesKey key,
    ) {
      ref.watch(libraryRevisionStateProvider.select((s) => s.revision));
      return ref.watch(imageSetImagesQueryProvider)(
        key.libraryId,
        key.imageSetId,
      );
    });

final imageSetWorkspaceImagesProvider = FutureProvider.autoDispose
    .family<List<ImageSetImage>, ImageSetImagesKey>((
      Ref ref,
      ImageSetImagesKey key,
    ) {
      ref.watch(libraryRevisionStateProvider.select((s) => s.revision));
      return ref.watch(imageSetWorkspaceImagesQueryProvider)(
        key.libraryId,
        key.imageSetId,
      );
    });

final imageSetFacetsProvider = FutureProvider.autoDispose
    .family<ImageSetFacets, String>((Ref ref, String imageSetId) {
      ref.watch(libraryRevisionStateProvider.select((s) => s.revision));
      return ref.watch(imageSetFacetsQueryProvider)(imageSetId);
    });

final imageSetReaderSessionProvider = FutureProvider.autoDispose
    .family<ImageSetReaderSession, ImageSetReaderEntry>(
      (Ref ref, ImageSetReaderEntry entry) =>
          ref.watch(imageSetReaderSessionQueryProvider)(entry),
    );

final imageSetPageBytesProvider = FutureProvider.autoDispose
    .family<Uint8List, ImageSetPageBytesKey>(
      (Ref ref, ImageSetPageBytesKey key) =>
          ref.watch(imageSetPageBytesQueryProvider)(key.libraryId, key.image),
    );
