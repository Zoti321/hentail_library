import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/image_set_library/application/load_image_set_catalog_page_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/load_image_set_facets_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/load_image_set_images_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/load_image_set_workspace_images_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/load_image_sets_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/open_image_set_reader_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/reorder_image_set_images_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/set_image_set_images_excluded_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/sync_image_set_library_use_case.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_entry.dart';
import 'package:hentai_library/features/image_set_library/infrastructure/repositories/image_set_browse_preferences_repository_impl.dart';
import 'package:hentai_library/features/image_set_library/infrastructure/repositories/image_set_repository_impl.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_browse_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_reader_page.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/shared/ui/navigation/app_root_navigator_key.dart';
import 'package:riverpod/misc.dart' show Override;

/// image_set_library owner：目录 query、同步 command 与 Reader 入口回调绑定。
List<Override> imageSetLibraryOverrides() {
  const ImageSetRepositoryImpl repository = ImageSetRepositoryImpl();
  final LoadImageSetsUseCase loadSets = LoadImageSetsUseCase(repository);
  final LoadImageSetCatalogPageUseCase loadCatalogPage =
      LoadImageSetCatalogPageUseCase(repository);
  final LoadImageSetFacetsUseCase loadFacets = LoadImageSetFacetsUseCase(
    repository,
  );
  final LoadImageSetImagesUseCase loadImages = LoadImageSetImagesUseCase(
    repository,
  );
  final LoadImageSetWorkspaceImagesUseCase loadWorkspaceImages =
      LoadImageSetWorkspaceImagesUseCase(repository);
  final SetImageSetImagesExcludedUseCase setExcluded =
      SetImageSetImagesExcludedUseCase(repository);
  final ReorderImageSetImagesUseCase reorderImages =
      ReorderImageSetImagesUseCase(repository);
  final OpenImageSetReaderUseCase openReader = OpenImageSetReaderUseCase(
    repository,
  );
  final LoadImageSetPageBytesUseCase loadBytes = LoadImageSetPageBytesUseCase(
    repository,
  );
  return <Override>[
    imageSetListQueryProvider.overrideWithValue(loadSets.call),
    imageSetCatalogPageQueryProvider.overrideWithValue(loadCatalogPage.call),
    imageSetBrowsePreferencesRepositoryProvider.overrideWithValue(
      const ImageSetBrowsePreferencesRepositoryImpl(),
    ),
    imageSetFacetsQueryProvider.overrideWithValue(loadFacets.call),
    imageSetImagesQueryProvider.overrideWithValue(loadImages.call),
    imageSetWorkspaceImagesQueryProvider.overrideWithValue(
      loadWorkspaceImages.call,
    ),
    imageSetSetImagesExcludedCommandProvider.overrideWithValue(setExcluded.call),
    imageSetReorderImagesCommandProvider.overrideWithValue(reorderImages.call),
    syncImageSetLibraryCommandProvider.overrideWith(
      (Ref ref) =>
          (String libraryId) => SyncImageSetLibraryUseCase(
            startScan: ref.read(startLibraryScanCommandProvider),
            readSyncState: () => ref.read(librarySyncStateProvider),
          ).call(libraryId),
    ),
    imageSetReaderSessionQueryProvider.overrideWithValue(openReader.call),
    imageSetPageBytesQueryProvider.overrideWithValue(loadBytes.call),
    imageSetReaderEntryCommandProvider.overrideWithValue(
      (ImageSetReaderEntry entry) =>
          pushImageSetReaderPage(appRootNavigatorKey.currentState, entry),
    ),
  ];
}
