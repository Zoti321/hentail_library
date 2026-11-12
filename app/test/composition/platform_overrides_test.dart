import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/composition/infrastructure_overrides.dart';
import 'package:hentai_library/features/app_settings/application/app_update_gateway.dart';
import 'package:hentai_library/features/app_settings/presentation/providers/app_setting_repository_provider.dart';
import 'package:hentai_library/features/app_settings/presentation/providers/app_update_providers.dart';
import 'package:hentai_library/features/comic_metadata/application/tag_dictionary_download_gateway.dart';
import 'package:hentai_library/features/comic_metadata/presentation/providers/comic_metadata_repository_providers.dart';
import 'package:hentai_library/features/comic_metadata/presentation/providers/download_providers.dart';
import 'package:hentai_library/features/library_admin/presentation/providers/comic_metadata_bulk_patch_providers.dart';
import 'package:hentai_library/features/library_admin/presentation/providers/library_sync_providers.dart';
import 'package:hentai_library/features/library_admin/presentation/providers/metadata_refresh_providers.dart';
import 'package:hentai_library/features/metadata_backup/presentation/providers/metadata_backup_repository_provider.dart';
import 'package:hentai_library/features/metadata_backup/presentation/providers/metadata_backup_use_case_providers.dart';
import 'package:hentai_library/features/reader/presentation/providers/page_image_copy_providers.dart';

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
        container.read(tagDictionaryDownloadGatewayProvider),
        isA<TagDictionaryDownloadGateway>(),
      );
      for (final Object? Function() read in <Object? Function()>[
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
