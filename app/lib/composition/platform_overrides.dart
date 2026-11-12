import 'package:hentai_library/features/comic_metadata/infrastructure/repositories/named_facet_form_listing.dart';
import 'package:hentai_library/features/comic_metadata/presentation/providers/comic_metadata_repository_providers.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:hentai_library/composition/modules/app_settings/app_setting_repository_factory.dart';
import 'package:hentai_library/features/app_settings/infrastructure/services/app_update/github_app_update_gateway.dart';
import 'package:hentai_library/features/app_settings/presentation/providers/app_setting_repository_provider.dart';
import 'package:hentai_library/features/app_settings/presentation/providers/app_update_providers.dart';
import 'package:hentai_library/features/comic_metadata/infrastructure/services/tag_dictionary/dio_tag_dictionary_download_gateway.dart';
import 'package:hentai_library/features/comic_metadata/presentation/providers/download_providers.dart';
import 'package:hentai_library/features/library_admin/infrastructure/adapters/sync_library_frb_adapter.dart';
import 'package:hentai_library/features/library_admin/infrastructure/adapters/metadata_refresh_frb_adapter.dart';
import 'package:hentai_library/features/library_admin/infrastructure/adapters/comic_metadata_bulk_patch_frb_adapter.dart';
import 'package:hentai_library/features/library_admin/infrastructure/local_library_root_access.dart';
import 'package:hentai_library/features/library_admin/presentation/providers/library_sync_providers.dart';
import 'package:hentai_library/features/library_admin/presentation/providers/metadata_refresh_providers.dart';
import 'package:hentai_library/features/library_admin/presentation/providers/comic_metadata_bulk_patch_providers.dart';
import 'package:hentai_library/features/library_admin/public/providers/library_admin_state_providers.dart';
import 'package:hentai_library/features/metadata_backup/infrastructure/metadata_backup_file_gateway.dart';
import 'package:hentai_library/features/metadata_backup/infrastructure/metadata_backup_paths.dart';
import 'package:hentai_library/features/metadata_backup/infrastructure/repositories/metadata_backup_repository_impl.dart';
import 'package:hentai_library/features/metadata_backup/presentation/providers/metadata_backup_repository_provider.dart';
import 'package:hentai_library/features/metadata_backup/presentation/providers/metadata_backup_use_case_providers.dart';
import 'package:hentai_library/features/reader/infrastructure/adapters/page_image_png_encoder.dart';
import 'package:hentai_library/features/reader/infrastructure/adapters/system_clipboard_image_adapter.dart';
import 'package:hentai_library/features/reader/presentation/providers/page_image_copy_providers.dart';

List<Override> platformOverrides() => <Override>[
  namedFacetFormListingProvider.overrideWith(
    (ref) => const NamedFacetFormListingImpl(),
  ),
  appSettingRepositoryProvider.overrideWith(
    (ref) => createAppSettingRepository(),
  ),
  appUpdateGatewayProvider.overrideWith((ref) => GitHubAppUpdateGateway()),
  tagDictionaryDownloadGatewayProvider.overrideWith(
    (ref) => DioTagDictionaryDownloadGateway(),
  ),
  syncLibraryPortProvider.overrideWith(
    (ref) =>
        SyncLibraryFrbAdapter(libraryRepository: ref.read(libraryRepoProvider)),
  ),
  localFilesystemAccessProvider.overrideWithValue(ensureLocalFilesystemAccess),
  localLibraryRootReadableProvider.overrideWithValue(
    isLocalLibraryRootReadable,
  ),
  metadataRefreshPortProvider.overrideWith(
    (ref) => MetadataRefreshFrbAdapter(
      libraryRepository: ref.read(libraryRepoProvider),
    ),
  ),
  comicMetadataBulkPatchPortProvider.overrideWith(
    (ref) => ComicMetadataBulkPatchFrbAdapter(
      libraryRepository: ref.read(libraryRepoProvider),
    ),
  ),
  metadataBackupRepositoryProvider.overrideWith(
    (ref) => const MetadataBackupRepositoryImpl(),
  ),
  metadataBackupFileGatewayProvider.overrideWith(
    (ref) => const LocalMetadataBackupFileGateway(),
  ),
  metadataBackupDirectoryQueryProvider.overrideWithValue(
    metadataBackupsDirectory,
  ),
  clipboardImagePortProvider.overrideWith(
    (ref) => const SystemClipboardImageAdapter(),
  ),
  pageImagePngEncoderProvider.overrideWithValue(encodePageImagePng),
];
