import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/image_set_library/application/load_image_set_catalog_page_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/load_image_set_facets_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/load_image_set_library_gates_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/load_image_set_images_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/add_image_set_submission_members_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/copy_images_into_image_set_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/create_image_set_submission_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/delete_image_set_images_on_disk_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/delete_image_set_submission_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/load_image_set_submissions_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/load_image_set_workspace_images_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/remove_image_set_submission_members_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/rename_image_set_submission_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/reorder_image_set_submission_members_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/load_image_sets_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/open_image_set_reader_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/reorder_image_set_images_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/set_image_set_images_excluded_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/set_image_set_managed_layout_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/set_image_set_resource_mutation_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/set_image_set_name_locked_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/sync_image_set_library_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/take_over_image_set_managed_layout_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/update_image_set_facets_use_case.dart';
import 'package:hentai_library/features/image_set_library/application/update_image_set_name_use_case.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_entry.dart';
import 'package:hentai_library/shared/presentation/providers/domain_event_bus_providers.dart';
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
  final LoadImageSetSubmissionsUseCase loadSubmissions =
      LoadImageSetSubmissionsUseCase(repository);
  final CreateImageSetSubmissionUseCase createSubmission =
      CreateImageSetSubmissionUseCase(repository);
  final RenameImageSetSubmissionUseCase renameSubmission =
      RenameImageSetSubmissionUseCase(repository);
  final DeleteImageSetSubmissionUseCase deleteSubmission =
      DeleteImageSetSubmissionUseCase(repository);
  final AddImageSetSubmissionMembersUseCase addSubmissionMembers =
      AddImageSetSubmissionMembersUseCase(repository);
  final RemoveImageSetSubmissionMembersUseCase removeSubmissionMembers =
      RemoveImageSetSubmissionMembersUseCase(repository);
  final ReorderImageSetSubmissionMembersUseCase reorderSubmissionMembers =
      ReorderImageSetSubmissionMembersUseCase(repository);
  final OpenImageSetReaderUseCase openReader = OpenImageSetReaderUseCase(
    repository,
  );
  final LoadImageSetPageBytesUseCase loadBytes = LoadImageSetPageBytesUseCase(
    repository,
  );
  final LoadImageSetLibraryGatesUseCase loadGates =
      LoadImageSetLibraryGatesUseCase(repository);
  final SetImageSetResourceMutationUseCase setResourceMutation =
      SetImageSetResourceMutationUseCase(repository);
  final SetImageSetManagedLayoutUseCase setManagedLayout =
      SetImageSetManagedLayoutUseCase(repository);
  return <Override>[
    imageSetListQueryProvider.overrideWithValue(loadSets.call),
    imageSetCatalogPageQueryProvider.overrideWithValue(loadCatalogPage.call),
    imageSetBrowsePreferencesRepositoryProvider.overrideWithValue(
      const ImageSetBrowsePreferencesRepositoryImpl(),
    ),
    imageSetFacetsQueryProvider.overrideWithValue(loadFacets.call),
    imageSetUpdateNameCommandProvider.overrideWith(
      (Ref ref) => UpdateImageSetNameUseCase(
        repository,
        ref.read(domainEventBusProvider),
      ).call,
    ),
    imageSetSetNameLockedCommandProvider.overrideWith(
      (Ref ref) => SetImageSetNameLockedUseCase(
        repository,
        ref.read(domainEventBusProvider),
      ).call,
    ),
    imageSetUpdateFacetsCommandProvider.overrideWith(
      (Ref ref) => UpdateImageSetFacetsUseCase(
        repository,
        ref.read(domainEventBusProvider),
      ).call,
    ),
    imageSetLibraryGatesQueryProvider.overrideWithValue(loadGates.call),
    imageSetSetResourceMutationCommandProvider.overrideWithValue(
      setResourceMutation.call,
    ),
    imageSetSetManagedLayoutCommandProvider.overrideWithValue(
      setManagedLayout.call,
    ),
    imageSetCopyImagesInCommandProvider.overrideWith(
      (Ref ref) => CopyImagesIntoImageSetUseCase(
        repository,
        ref.read(domainEventBusProvider),
      ).call,
    ),
    imageSetDeleteImagesOnDiskCommandProvider.overrideWith(
      (Ref ref) => DeleteImageSetImagesOnDiskUseCase(
        repository,
        ref.read(domainEventBusProvider),
      ).call,
    ),
    imageSetTakeOverManagedLayoutCommandProvider.overrideWith(
      (Ref ref) => TakeOverImageSetManagedLayoutUseCase(
        repository,
        ref.read(domainEventBusProvider),
      ).call,
    ),
    imageSetImagesQueryProvider.overrideWithValue(loadImages.call),
    imageSetWorkspaceImagesQueryProvider.overrideWithValue(
      loadWorkspaceImages.call,
    ),
    imageSetSetImagesExcludedCommandProvider.overrideWithValue(setExcluded.call),
    imageSetReorderImagesCommandProvider.overrideWithValue(reorderImages.call),
    imageSetSubmissionsQueryProvider.overrideWithValue(loadSubmissions.call),
    imageSetCreateSubmissionCommandProvider.overrideWithValue(
      createSubmission.call,
    ),
    imageSetRenameSubmissionCommandProvider.overrideWithValue(
      renameSubmission.call,
    ),
    imageSetDeleteSubmissionCommandProvider.overrideWithValue(
      deleteSubmission.call,
    ),
    imageSetAddSubmissionMembersCommandProvider.overrideWithValue(
      addSubmissionMembers.call,
    ),
    imageSetRemoveSubmissionMembersCommandProvider.overrideWithValue(
      removeSubmissionMembers.call,
    ),
    imageSetReorderSubmissionMembersCommandProvider.overrideWithValue(
      reorderSubmissionMembers.call,
    ),
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
