import 'package:hentai_library/features/comic_metadata/infrastructure/metadata_management_preferences.dart';
import 'package:hentai_library/features/comic_metadata/infrastructure/services/tag_dictionary/read_tag_dictionary_file.dart';
import 'package:hentai_library/features/comic_metadata/presentation/providers/metadata_management_preferences_providers.dart';
import 'package:hentai_library/features/comic_metadata/presentation/providers/tag_dictionary_file_provider.dart';
import 'package:hentai_library/features/series/infrastructure/series_detail_page_size_storage.dart';
import 'package:hentai_library/features/series/presentation/providers/series_page_size_storage_providers.dart';
import 'package:hentai_library/features/library_admin/infrastructure/library_migration_store_impl.dart';
import 'package:hentai_library/features/library_admin/presentation/providers/library_migration_store_provider.dart';
import 'package:hentai_library/features/metadata_backup/infrastructure/metadata_backup_preferences_repository_impl.dart';
import 'package:hentai_library/features/metadata_backup/presentation/providers/metadata_backup_preferences_provider.dart';
import 'package:hentai_library/composition/logging_composition.dart';
import 'package:hentai_library/composition/window_composition.dart';
import 'package:hentai_library/infrastructure/logging/diagnostic_logging.dart';
import 'package:hentai_library/infrastructure/platform/shell_file_explorer.dart';
import 'package:hentai_library/shared/presentation/providers/file_explorer_providers.dart';
import 'package:hentai_library/features/app_settings/infrastructure/diagnostics/export_logs.dart';
import 'package:hentai_library/features/app_settings/infrastructure/services/app_update/open_downloaded_update.dart';
import 'package:hentai_library/features/app_settings/presentation/providers/app_update_opener_providers.dart';
import 'package:hentai_library/features/app_settings/presentation/providers/diagnostic_providers.dart';
import 'package:hentai_library/features/comic_metadata/infrastructure/repositories/named_facet_form_listing.dart';
import 'package:hentai_library/features/comic_metadata/presentation/providers/comic_metadata_repository_providers.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:hentai_library/composition/modules/app_settings/app_setting_repository_factory.dart';
import 'package:hentai_library/features/app_settings/infrastructure/services/app_update/github_app_update_gateway.dart';
import 'package:hentai_library/features/app_settings/presentation/providers/app_setting_repository_provider.dart';
import 'package:hentai_library/features/app_settings/presentation/providers/app_update_providers.dart';
import 'package:hentai_library/features/app_settings/infrastructure/load_installed_app_version.dart';
import 'package:hentai_library/features/app_settings/presentation/providers/installed_app_version_providers.dart';
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
import 'package:hentai_library/features/reader/presentation/providers/reader_window_providers.dart';
import 'package:hentai_library/features/library_browse/infrastructure/open_author_link.dart';
import 'package:hentai_library/features/library_browse/presentation/providers/author_link_providers.dart';

List<Override> platformOverrides() => <Override>[
  openAuthorLinkCommandProvider.overrideWithValue(openAuthorLink),
  readerWindowFullscreenCommandProvider.overrideWithValue(
    setAppWindowFullscreen,
  ),
  mergeConfirmationSkippedQueryProvider.overrideWithValue(
    loadMergeConfirmationSkipped,
  ),
  setMergeConfirmationSkippedCommandProvider.overrideWithValue(
    saveMergeConfirmationSkipped,
  ),
  readTagDictionaryFileProvider.overrideWithValue(readTagDictionaryFile),
  seriesDetailPageSizeQueryProvider.overrideWithValue(loadSeriesDetailPageSize),
  setSeriesDetailPageSizeCommandProvider.overrideWithValue(
    saveSeriesDetailPageSize,
  ),
  libraryMigrationStoreProvider.overrideWith(
    (ref) => const LibraryMigrationStoreImpl(),
  ),
  metadataBackupPreferencesRepositoryProvider.overrideWith(
    (ref) => const MetadataBackupPreferencesRepositoryImpl(),
  ),
  showInFileExplorerProvider.overrideWithValue(showInFileExplorer),
  openDirectoryInFileExplorerProvider.overrideWithValue(
    openDirectoryInFileExplorer,
  ),
  openDownloadedUpdateProvider.overrideWithValue(openDownloadedUpdateFile),
  openReleasePageProvider.overrideWithValue(openReleasePage),
  diagnosticLoggingCommandProvider.overrideWithValue(applyDiagnosticLogging),
  exportLogsCommandProvider.overrideWithValue(
    ({
      required String outputPath,
      required bool redact,
      required bool diagnosticVerbose,
    }) => exportLogs(
      outputPath: outputPath,
      redact: redact,
      diagnosticVerbose: diagnosticVerbose,
      flush: flushAppLogs,
    ),
  ),
  namedFacetFormListingProvider.overrideWith(
    (ref) => const NamedFacetFormListingImpl(),
  ),
  appSettingRepositoryProvider.overrideWith(
    (ref) => createAppSettingRepository(),
  ),
  appUpdateGatewayProvider.overrideWith((ref) => GitHubAppUpdateGateway()),
  installedAppVersionQueryProvider.overrideWithValue(loadInstalledAppVersion),
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
