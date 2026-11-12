import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hentai_library/features/library_admin/application/load_libraries_use_case.dart';
import 'package:hentai_library/features/library_admin/public/di/library_admin_state_providers.dart';
import 'package:hentai_library/features/app_settings/public/di/app_settings_providers.dart';

final loadLibrariesUseCaseProvider = Provider<LoadLibrariesUseCase>((ref) {
  final settings = ref.read(appSettingRepositoryProvider);
  return LoadLibrariesUseCase(
    repository: ref.read(libraryRepoProvider),
    readFlag: (key) async =>
        (await SharedPreferences.getInstance()).getBool(key),
    writeFlag: (key, value) async {
      await (await SharedPreferences.getInstance()).setBool(key, value);
    },
    peekLegacyResourceFormatPayload: settings.peekLegacyResourceFormatPayload,
    peekLegacyAutoScan: settings.peekLegacyAutoScan,
    clearLegacyImportPayload: settings.clearLegacyImportPayload,
  );
});
