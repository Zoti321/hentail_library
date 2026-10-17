import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_admin/di/shared_state_ports.dart';
import 'package:hentai_library/features/library_browse/di/comic_detail_return_series_ports.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/current_library_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_reorder_mode_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_revision_notifier.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_revision_throttle_busy.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_series_providers.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/comic_metadata_bulk_patch_controller.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/metadata_refresh_controller.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/scan_library_controller.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/library_comic_filters_notifier.dart';
import 'package:hentai_library/features/metadata_backup/data/recent_metadata_backup_at.dart';
import 'package:hentai_library/features/metadata_backup/presentation/views/metadata_backup_settings_detail.dart';
import 'package:hentai_library/features/app_settings/di/shared_state_ports.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/shared/di/app_settings_providers.dart';
import 'package:hentai_library/features/comic_trash/di/comic_trash_command_port.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/author_management_notifier.dart';
import 'package:hentai_library/features/named_metadata/presentation/view_models/tag_management_notifier.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
import 'package:hentai_library/shared/di/library_command_providers.dart';
import 'package:hentai_library/shared/di/library_dictionary_providers.dart';
import 'package:hentai_library/shared/di/settings_slot_providers.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_layout_constants.dart';
import 'package:hentai_library/shared/domain/library/library_age_restriction_filter.dart';
import 'package:riverpod/misc.dart' show Override;

/// bootstrap 组装：把 library_admin 的实现注入 shared/di 声明的状态与端口 Provider（#261a）。
///
/// 位于 bootstrap（组合根），因此允许同时依赖 shared 与 library_admin。
List<Override> sharedLibraryStateOverrides() => <Override>[
  currentLibraryPortProvider.overrideWith(createCurrentLibraryPort),
  libraryReorderModePortProvider.overrideWith(createLibraryReorderModePort),
  libraryReorderActiveStateProvider.overrideWith(
    (Ref ref) => ref.watch(libraryReorderModeProvider),
  ),
  libraryRevisionSignalPortProvider.overrideWith(
    createLibraryRevisionSignalPort,
  ),
  comicMetadataBulkEditCommandPortProvider.overrideWith(
    createComicMetadataBulkEditCommandPort,
  ),
  libraryScanCommandPortProvider.overrideWith(createLibraryScanCommandPort),
  comicDetailReturnSeriesPortProvider.overrideWith(
    createComicDetailReturnSeriesPort,
  ),
  currentLibraryStateProvider.overrideWith(
    (Ref ref) => ref.watch(currentLibraryProvider),
  ),
  libraryRevisionStateProvider.overrideWith(
    (Ref ref) => ref.watch(libraryRevisionProvider),
  ),
  libraryRevisionThrottleBusyStateProvider.overrideWith(
    (Ref ref) => ref.watch(libraryRevisionThrottleBusyProvider),
  ),
  seriesByIdStateProvider.overrideWith(
    (Ref ref, String seriesId) =>
        ref.watch(seriesByIdProvider(seriesId).future),
  ),
  libraryComicAgeRestrictionStateProvider.overrideWith(
    (Ref ref) => ref.watch(
      libraryComicFiltersProvider.select(
        (AsyncValue<LibraryComicFiltersState> state) =>
            state.value?.ageRestriction ??
            LibraryAgeRestrictionFilter.unrestricted,
      ),
    ),
  ),
  libraryMutationBusyStateProvider.overrideWith(
    (Ref ref) =>
        ref.watch(scanLibraryControllerProvider.select((s) => s.running)) ||
        ref.watch(metadataRefreshControllerProvider.select((s) => s.running)) ||
        ref.watch(
          comicMetadataBulkPatchControllerProvider.select((s) => s.running),
        ),
  ),
  metadataBackupSettingsSectionBuilderProvider.overrideWithValue(
    (SettingsLayoutTier layoutTier, bool showTitle) =>
        MetadataBackupSettingsDetail(
          layoutTier: layoutTier,
          showTitle: showTitle,
        ),
  ),
  recentMetadataBackupAtReaderProvider.overrideWithValue(
    readRecentMetadataBackupAt,
  ),
  appSettingsStateProvider.overrideWith(
    (Ref ref) => ref.watch(settingsProvider),
  ),
  appSettingsFutureProvider.overrideWith(
    (Ref ref) => ref.watch(settingsProvider.future),
  ),
  readerSettingsCommandPortProvider.overrideWith(
    createReaderSettingsCommandPort,
  ),
  comicTrashCommandPortProvider.overrideWith(createComicTrashCommandPort),
  libraryTagDictionaryStateProvider.overrideWith(
    (Ref ref) => ref.watch(allTagsProvider),
  ),
  libraryAuthorDictionaryStateProvider.overrideWith(
    (Ref ref) => ref.watch(allAuthorsProvider),
  ),
  libraryScanRunningStateProvider.overrideWith(
    (Ref ref) =>
        ref.watch(scanLibraryControllerProvider.select((s) => s.running)),
  ),
];
