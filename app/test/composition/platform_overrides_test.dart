import 'package:hentai_library/features/comic_metadata/presentation/providers/metadata_management_preferences_providers.dart';
import 'package:hentai_library/features/comic_metadata/presentation/providers/tag_dictionary_file_provider.dart';
import 'package:hentai_library/features/series/presentation/providers/series_page_size_storage_providers.dart';
import 'package:hentai_library/features/library_admin/application/library_migration_store.dart';
import 'package:hentai_library/features/library_admin/presentation/providers/library_migration_store_provider.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_preferences_repository.dart';
import 'package:hentai_library/features/metadata_backup/presentation/providers/metadata_backup_preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/composition/infrastructure_overrides.dart';
import 'package:hentai_library/shared/presentation/providers/file_explorer_providers.dart';
import 'package:hentai_library/features/app_settings/presentation/providers/app_update_opener_providers.dart';
import 'package:hentai_library/features/app_settings/presentation/providers/diagnostic_providers.dart';
import 'package:hentai_library/features/app_settings/application/app_update_gateway.dart';
import 'package:hentai_library/features/app_settings/presentation/providers/app_setting_repository_provider.dart';
import 'package:hentai_library/features/app_settings/presentation/providers/app_update_providers.dart';
import 'package:hentai_library/features/app_settings/presentation/providers/installed_app_version_providers.dart';
import 'package:hentai_library/features/comic_metadata/application/tag_dictionary_download_gateway.dart';
import 'package:hentai_library/features/comic_metadata/presentation/providers/comic_metadata_repository_providers.dart';
import 'package:hentai_library/features/comic_metadata/presentation/providers/download_providers.dart';
import 'package:hentai_library/features/library_admin/presentation/providers/comic_metadata_bulk_patch_providers.dart';
import 'package:hentai_library/features/library_admin/presentation/providers/library_sync_providers.dart';
import 'package:hentai_library/features/library_admin/presentation/providers/metadata_refresh_providers.dart';
import 'package:hentai_library/features/metadata_backup/presentation/providers/metadata_backup_repository_provider.dart';
import 'package:hentai_library/features/metadata_backup/presentation/providers/metadata_backup_use_case_providers.dart';
import 'package:hentai_library/features/reader/presentation/providers/page_image_copy_providers.dart';
import 'package:hentai_library/features/reader/presentation/providers/reader_window_providers.dart';
import 'package:hentai_library/features/library_browse/presentation/providers/author_link_providers.dart';
import 'package:hentai_library/features/library_browse/domain/browse/library_browse_preferences_repository.dart';
import 'package:hentai_library/features/library_browse/presentation/providers/library_browse_preferences_provider.dart';
import 'package:hentai_library/features/home/domain/home_alert_dismiss_repository.dart';
import 'package:hentai_library/features/home/presentation/providers/home_alert_dismiss_repository_provider.dart';

void main() {
  test(
    'production assembly supplies platform dependencies without executing IO',
    () {
      final ProviderContainer container = ProviderContainer(
        overrides: infrastructureOverrides(),
      );
      addTearDown(container.dispose);

      expect(container.read(appUpdateGatewayProvider), isA<AppUpdateGateway>());
      expect(
        container.read(libraryMigrationStoreProvider),
        isA<LibraryMigrationStore>(),
      );
      expect(
        container.read(metadataBackupPreferencesRepositoryProvider),
        isA<MetadataBackupPreferencesRepository>(),
      );
      expect(
        container.read(homeAlertDismissRepositoryProvider),
        isA<HomeAlertDismissRepository>(),
      );
      expect(
        container.read(libraryBrowsePreferencesRepositoryProvider),
        isA<LibraryBrowsePreferencesRepository>(),
      );
      expect(
        container.read(tagDictionaryDownloadGatewayProvider),
        isA<TagDictionaryDownloadGateway>(),
      );
      for (final Object? Function() read in <Object? Function()>[
        () => container.read(openAuthorLinkCommandProvider),
        () => container.read(readerWindowFullscreenCommandProvider),
        () => container.read(mergeConfirmationSkippedQueryProvider),
        () => container.read(setMergeConfirmationSkippedCommandProvider),
        () => container.read(readTagDictionaryFileProvider),
        () => container.read(seriesDetailPageSizeQueryProvider),
        () => container.read(setSeriesDetailPageSizeCommandProvider),
        () => container.read(showInFileExplorerProvider),
        () => container.read(openDirectoryInFileExplorerProvider),
        () => container.read(openDownloadedUpdateProvider),
        () => container.read(installedAppVersionQueryProvider),
        () => container.read(openReleasePageProvider),
        () => container.read(diagnosticLoggingCommandProvider),
        () => container.read(exportLogsCommandProvider),
        () => container.read(appSettingRepositoryProvider),
        () => container.read(namedFacetFormListingProvider),
        () => container.read(syncLibraryPortProvider),
        () => container.read(localFilesystemAccessProvider),
        () => container.read(localLibraryRootReadableProvider),
        () => container.read(metadataRefreshPortProvider),
        () => container.read(comicMetadataBulkPatchPortProvider),
        () => container.read(metadataBackupRepositoryProvider),
        () => container.read(metadataBackupFileGatewayProvider),
        () => container.read(metadataBackupDirectoryQueryProvider),
        () => container.read(clipboardImagePortProvider),
        () => container.read(pageImagePngEncoderProvider),
      ]) {
        expect(read(), isNotNull);
      }
    },
  );
}
