import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_admin/domain/libraries_port.dart';
import 'package:hentai_library/features/library_admin/domain/comic_metadata_bulk_edit_command_port.dart';
import 'package:hentai_library/shared/domain/library/comic_detail_return_series_port.dart';
import 'package:hentai_library/features/library_admin/domain/libraries_state.dart';
import 'package:hentai_library/features/library_admin/domain/library_scan_command_port.dart';
import 'package:hentai_library/features/library_admin/domain/library_reorder_mode_port.dart';
import 'package:hentai_library/features/library_admin/domain/library_revision_state.dart';
import 'package:hentai_library/shared/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/features/library_admin/domain/library_scan_activity_state.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:hentai_library/shared/domain/ports/library_revision_signal_port.dart';

/// 跨 feature 共享的库状态与端口 Provider 声明（#261a）。
///
/// 实现与 `createX…Port` 工厂见 owner
/// `features/library_admin/public.dart`（bootstrap override 注入）。

final Provider<LibrariesPort> librariesPortProvider =
    Provider<LibrariesPort>(
      (Ref ref) => throw UnimplementedError(
        'librariesPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );

final Provider<LibraryReorderModePort> libraryReorderModePortProvider =
    Provider<LibraryReorderModePort>(
      (Ref ref) => throw UnimplementedError(
        'libraryReorderModePortProvider 未注入，请在 bootstrap 中 override',
      ),
    );

final Provider<bool> libraryReorderActiveStateProvider = Provider<bool>(
  (Ref ref) => throw UnimplementedError(
    'libraryReorderActiveStateProvider 未注入，请在 bootstrap 中 override',
  ),
);

final Provider<LibraryRevisionSignalPort> libraryRevisionSignalPortProvider =
    Provider<LibraryRevisionSignalPort>(
      (Ref ref) => throw UnimplementedError(
        'libraryRevisionSignalPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );

final Provider<ComicMetadataBulkEditCommandPort>
comicMetadataBulkEditCommandPortProvider =
    Provider<ComicMetadataBulkEditCommandPort>(
      (Ref ref) => throw UnimplementedError(
        'comicMetadataBulkEditCommandPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );

/// 导出当前库元数据：实现位于 metadata_backup，由 bootstrap 注入，library_browse 不直接依赖 metadata_backup。
final Provider<Future<void> Function(BuildContext context, String libraryId)>
libraryMetadataExportActionProvider =
    Provider<Future<void> Function(BuildContext context, String libraryId)>(
      (Ref ref) => throw UnimplementedError(
        'libraryMetadataExportActionProvider 未注入，请在 bootstrap 中 override',
      ),
    );

final Provider<LibraryScanCommandPort> libraryScanCommandPortProvider =
    Provider<LibraryScanCommandPort>(
      (Ref ref) => throw UnimplementedError(
        'libraryScanCommandPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );

final Provider<ComicDetailReturnSeriesPort>
comicDetailReturnSeriesPortProvider = Provider<ComicDetailReturnSeriesPort>(
  (Ref ref) => throw UnimplementedError(
    'comicDetailReturnSeriesPortProvider 未注入，请在 bootstrap 中 override',
  ),
);

final Provider<AsyncValue<LibrariesState>> librariesStateProvider =
    Provider<AsyncValue<LibrariesState>>(
      (Ref ref) => throw UnimplementedError(
        'librariesStateProvider 未注入，请在 bootstrap 中 override',
      ),
    );

final Provider<LibraryRevisionState> libraryRevisionStateProvider =
    Provider<LibraryRevisionState>(
      (Ref ref) => throw UnimplementedError(
        'libraryRevisionStateProvider 未注入，请在 bootstrap 中 override',
      ),
    );

/// Catalog / Home 应对 revision 降频的 busy 信号（原 `libraryRevisionThrottleBusyProvider`）。
final Provider<bool> libraryRevisionThrottleBusyStateProvider = Provider<bool>(
  (Ref ref) => throw UnimplementedError(
    'libraryRevisionThrottleBusyStateProvider 未注入，请在 bootstrap 中 override',
  ),
);

/// Home / Catalog 共用的 Comics 年龄限制（原 `libraryComicFiltersProvider` 的 ageRestriction 投影）。
final Provider<LibraryAgeRestrictionFilter>
libraryComicAgeRestrictionStateProvider = Provider<LibraryAgeRestrictionFilter>(
  (Ref ref) => throw UnimplementedError(
    'libraryComicAgeRestrictionStateProvider 未注入，请在 bootstrap 中 override',
  ),
);

/// library_admin 扫描是否进行中（原 `scanLibraryControllerProvider.running`）。
final Provider<bool> libraryScanRunningStateProvider = Provider<bool>(
  (Ref ref) => throw UnimplementedError(
    'libraryScanRunningStateProvider 未注入，请在 bootstrap 中 override',
  ),
);

final Provider<LibraryScanActivityState> libraryScanActivityStateProvider =
    Provider<LibraryScanActivityState>(
      (Ref ref) => throw UnimplementedError(
        'libraryScanActivityStateProvider 未注入，请在 bootstrap 中 override',
      ),
    );

final Provider<bool>
libraryMetadataRefreshRunningStateProvider = Provider<bool>(
  (Ref ref) => throw UnimplementedError(
    'libraryMetadataRefreshRunningStateProvider 未注入，请在 bootstrap 中 override',
  ),
);

/// 正在做「单库」元数据刷新时该库的 libraryId；否则为 null（列表行 busy 态用）。
final Provider<String?> libraryMetadataRefreshTargetLibraryIdStateProvider =
    Provider<String?>(
      (Ref ref) => throw UnimplementedError(
        'libraryMetadataRefreshTargetLibraryIdStateProvider 未注入，请在 bootstrap 中 override',
      ),
    );

/// 书库是否处于变更型后台任务中（扫描 / 元数据刷新 / 批量编辑任一运行），供 trash 等命令门控。
final Provider<bool> libraryMutationBusyStateProvider = Provider<bool>(
  (Ref ref) => throw UnimplementedError(
    'libraryMutationBusyStateProvider 未注入，请在 bootstrap 中 override',
  ),
);

/// 系列详情入口（原 `seriesByIdProvider`，按 id 查询）。
final seriesByIdStateProvider = FutureProvider.family<Series?, String>(
  (Ref ref, String seriesId) => throw UnimplementedError(
    'seriesByIdStateProvider 未注入，请在 bootstrap 中 override',
  ),
);
