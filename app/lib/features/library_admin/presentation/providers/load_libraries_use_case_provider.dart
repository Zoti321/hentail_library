import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_admin/presentation/providers/library_migration_store_provider.dart';
import 'package:hentai_library/features/library_admin/application/load_libraries_use_case.dart';
import 'package:hentai_library/features/library_admin/public/providers/library_admin_state_providers.dart';
import 'package:hentai_library/features/app_settings/public/providers/app_settings_providers.dart';

final loadLibrariesUseCaseProvider = Provider<LoadLibrariesUseCase>((ref) {
  final settings = ref.read(appSettingRepositoryProvider);
  return LoadLibrariesUseCase(
    repository: ref.read(libraryRepoProvider),
    migrations: ref.read(libraryMigrationStoreProvider),
    peekLegacyResourceFormatPayload: settings.peekLegacyResourceFormatPayload,
    peekLegacyAutoScan: settings.peekLegacyAutoScan,
    clearLegacyImportPayload: settings.clearLegacyImportPayload,
  );
});
