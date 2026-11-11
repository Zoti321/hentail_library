import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic_trash/public.dart';
import 'package:hentai_library/features/app_settings/public.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:hentai_library/shared/di/app_settings_providers.dart';

/// app_settings 与 comic_trash owner Port 注入（#435）。
List<Override> appSettingsAndTrashSharedStateOverrides() => <Override>[
  readerSettingsCommandPortProvider.overrideWith(
    createReaderSettingsCommandPort,
  ),
  appThemePreferencesPortProvider.overrideWith(createAppThemePreferencesPort),
  readerDisplayPreferencesPortProvider.overrideWith(
    createReaderDisplayPreferencesPort,
  ),
  comicTrashCommandPortProvider.overrideWith(createComicTrashCommandPort),
  appSettingsStateProvider.overrideWith(
    (Ref ref) => ref.watch(settingsProvider),
  ),
  appSettingsFutureProvider.overrideWith(
    (Ref ref) => ref.watch(settingsProvider.future),
  ),
];
