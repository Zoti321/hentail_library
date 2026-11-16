import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/image_set_library/application/load_image_set_images_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/load_image_sets_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/sync_image_set_library_use_case.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_entry.dart';
import 'package:hentai_library/features/image_set_library/infrastructure/repositories/image_set_repository_impl.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:riverpod/misc.dart' show Override;

/// image_set_library owner：目录 query、同步 command 与 Reader 入口回调绑定。
List<Override> imageSetLibraryOverrides() {
  const ImageSetRepositoryImpl repository = ImageSetRepositoryImpl();
  final LoadImageSetsUseCase loadSets = LoadImageSetsUseCase(repository);
  final LoadImageSetImagesUseCase loadImages = LoadImageSetImagesUseCase(
    repository,
  );
  return <Override>[
    imageSetListQueryProvider.overrideWithValue(loadSets.call),
    imageSetImagesQueryProvider.overrideWithValue(loadImages.call),
    syncImageSetLibraryCommandProvider.overrideWith(
      (Ref ref) =>
          (String libraryId) => SyncImageSetLibraryUseCase(
            startScan: ref.read(startLibraryScanCommandProvider),
            readSyncState: () => ref.read(librarySyncStateProvider),
          ).call(libraryId),
    ),
    // Reader session 尚未接入（#586）：入口回调暂不发起阅读，仅保留契约供测试替换。
    imageSetReaderEntryCommandProvider.overrideWithValue(
      (ImageSetReaderEntry entry) {},
    ),
  ];
}
