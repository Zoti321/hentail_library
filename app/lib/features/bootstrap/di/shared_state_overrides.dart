import 'package:hentai_library/features/bootstrap/di/overrides/app_settings_trash_shared_state_overrides.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/features/bootstrap/di/overrides/library_browse_shared_state_overrides.dart';
import 'package:hentai_library/features/bootstrap/di/overrides/metadata_dictionary_shared_state_overrides.dart';
import 'package:hentai_library/features/bootstrap/di/overrides/reading_history_shared_state_overrides.dart';
import 'package:riverpod/misc.dart' show Override;

/// bootstrap 组装：owner public 实现注入 shared/di 声明的 Provider（#261a / #435）。
List<Override> sharedLibraryStateOverrides() => <Override>[
  ...libraryAdminSharedStateOverrides(),
  ...libraryBrowseSharedStateOverrides(),
  ...metadataAndDictionarySharedStateOverrides(),
  ...appSettingsAndTrashSharedStateOverrides(),
  ...readingHistorySharedStateOverrides(),
];
