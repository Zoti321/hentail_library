import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:riverpod/misc.dart' show FutureProviderFamily;
import 'package:hentai_library/features/library_admin/domain/libraries_port.dart';
import 'package:hentai_library/features/library_admin/domain/comic_metadata_bulk_edit_command_port.dart';
import 'package:hentai_library/shared/domain/library/comic_detail_return_series_port.dart';
import 'package:hentai_library/shared/domain/library/libraries_state.dart';
import 'package:hentai_library/features/library_admin/domain/library_scan_command_port.dart';
import 'package:hentai_library/features/library_admin/domain/library_reorder_mode_port.dart';
import 'package:hentai_library/shared/domain/library/library_revision_state.dart';
import 'package:hentai_library/shared/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/shared/domain/library/library_scan_activity_state.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';

/// 跨 feature 共享的库状态与端口 Provider 声明（#261a）。
///
/// 实现与 `createX…Port` 工厂见 owner
/// `features/library_admin/public.dart`（bootstrap override 注入）。

final Provider<LibrariesPort> librariesPortProvider = injectedDi(
  'librariesPortProvider',
);

final Provider<LibraryReorderModePort> libraryReorderModePortProvider =
    injectedDi('libraryReorderModePortProvider');

final Provider<bool> libraryReorderActiveStateProvider = injectedDi(
  'libraryReorderActiveStateProvider',
);

final Provider<ComicMetadataBulkEditCommandPort>
comicMetadataBulkEditCommandPortProvider = injectedDi(
  'comicMetadataBulkEditCommandPortProvider',
);

/// 导出当前库元数据：实现位于 metadata_backup，由 bootstrap 注入，library_browse 不直接依赖 metadata_backup。
final Provider<Future<void> Function(BuildContext context, String libraryId)>
libraryMetadataExportActionProvider = injectedDi(
  'libraryMetadataExportActionProvider',
);

final Provider<LibraryScanCommandPort> libraryScanCommandPortProvider =
    injectedDi('libraryScanCommandPortProvider');

final Provider<ComicDetailReturnSeriesPort>
comicDetailReturnSeriesPortProvider = injectedDi(
  'comicDetailReturnSeriesPortProvider',
);

final Provider<AsyncValue<LibrariesState>> librariesStateProvider = injectedDi(
  'librariesStateProvider',
);

final Provider<LibraryRevisionState> libraryRevisionStateProvider = injectedDi(
  'libraryRevisionStateProvider',
);

/// Catalog / Home 应对 revision 降频的 busy 信号（原 `libraryRevisionThrottleBusyProvider`）。
final Provider<bool> libraryRevisionThrottleBusyStateProvider = injectedDi(
  'libraryRevisionThrottleBusyStateProvider',
);

/// Home / Catalog 共用的 Comics 年龄限制（原 `libraryComicFiltersProvider` 的 ageRestriction 投影）。
final Provider<LibraryAgeRestrictionFilter>
libraryComicAgeRestrictionStateProvider = injectedDi(
  'libraryComicAgeRestrictionStateProvider',
);

/// library_admin 扫描是否进行中（原 `scanLibraryControllerProvider.running`）。
final Provider<bool> libraryScanRunningStateProvider = injectedDi(
  'libraryScanRunningStateProvider',
);

final Provider<LibraryScanActivityState> libraryScanActivityStateProvider =
    injectedDi('libraryScanActivityStateProvider');

final Provider<bool> libraryMetadataRefreshRunningStateProvider = injectedDi(
  'libraryMetadataRefreshRunningStateProvider',
);

/// 正在做「单库」元数据刷新时该库的 libraryId；否则为 null（列表行 busy 态用）。
final Provider<String?> libraryMetadataRefreshTargetLibraryIdStateProvider =
    injectedDi('libraryMetadataRefreshTargetLibraryIdStateProvider');

/// 书库是否处于变更型后台任务中（扫描 / 元数据刷新 / 批量编辑任一运行），供 trash 等命令门控。
final Provider<bool> libraryMutationBusyStateProvider = injectedDi(
  'libraryMutationBusyStateProvider',
);

/// 系列详情入口（原 `seriesByIdProvider`，按 id 查询）。
final FutureProviderFamily<Series?, String> seriesByIdStateProvider =
    injectedFutureDiFamily('seriesByIdStateProvider');
