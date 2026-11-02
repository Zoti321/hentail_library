import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic_trash/public.dart';
import 'package:hentai_library/features/app_settings/di/shared_state_ports.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/shared/di/app_settings_providers.dart';
import 'package:hentai_library/shared/di/library_command_providers.dart';
import 'package:riverpod/misc.dart' show Override;

/// app_settings 与 comic_trash owner Port 注入（#435）。
List<Override> appSettingsAndTrashSharedStateOverrides() => <Override>[
  readerSettingsCommandPortProvider.overrideWith(
    createReaderSettingsCommandPort,
  ),
  comicTrashCommandPortProvider.overrideWith(createComicTrashCommandPort),
  appSettingsStateProvider.overrideWith(
    (Ref ref) => ref.watch(settingsProvider),
  ),
  appSettingsFutureProvider.overrideWith(
    (Ref ref) => ref.watch(settingsProvider.future),
  ),
];
