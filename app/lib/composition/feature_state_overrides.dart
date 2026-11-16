import 'package:hentai_library/composition/overrides/app_settings_trash_shared_state_overrides.dart';
import 'package:hentai_library/composition/modules/library_admin/library_admin_shared_state_overrides.dart';
import 'package:hentai_library/composition/overrides/comic_series_shared_state_overrides.dart';
import 'package:hentai_library/composition/overrides/library_browse_shared_state_overrides.dart';
import 'package:hentai_library/composition/overrides/metadata_dictionary_shared_state_overrides.dart';
import 'package:hentai_library/composition/overrides/reading_history_shared_state_overrides.dart';
import 'package:hentai_library/composition/overrides/reading_stats_shared_state_overrides.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:hentai_library/composition/modules/resource_metadata/writeback_overrides.dart';
import 'package:hentai_library/composition/modules/image_set_library/image_set_library_overrides.dart';

/// 将模块状态适配器绑定到共享 Provider。
List<Override> featureStateOverrides() => <Override>[
  ...writebackOverrides(),
  ...libraryAdminSharedStateOverrides(),
  ...imageSetLibraryOverrides(),
  ...libraryBrowseSharedStateOverrides(),
  ...comicSeriesSharedStateOverrides(),
  ...metadataAndDictionarySharedStateOverrides(),
  ...appSettingsAndTrashSharedStateOverrides(),
  ...readingHistorySharedStateOverrides(),
  ...readingStatsSharedStateOverrides(),
];
