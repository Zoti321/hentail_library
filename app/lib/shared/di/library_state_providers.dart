import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/library/current_library_port.dart';
import 'package:hentai_library/shared/domain/library/comic_metadata_bulk_edit_command_port.dart';
import 'package:hentai_library/shared/domain/library/comic_detail_return_series_port.dart';
import 'package:hentai_library/shared/domain/library/current_library_state.dart';
import 'package:hentai_library/shared/domain/library/library_scan_command_port.dart';
import 'package:hentai_library/shared/domain/library/library_reorder_mode_port.dart';
import 'package:hentai_library/shared/domain/library/library_revision_state.dart';
import 'package:hentai_library/shared/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:hentai_library/shared/domain/ports/library_revision_signal_port.dart';

/// 跨 feature 共享的库状态与端口 Provider 声明（#261a）。
///
/// 这里只声明、不实现：默认值抛 [UnimplementedError]，
/// 由 bootstrap 的 `ProviderScope(overrides: ...)` 注入 library_admin 的实现。
/// 消费方在后续 slice（261e）中改为依赖这些 Provider。

final Provider<CurrentLibraryPort> currentLibraryPortProvider =
    Provider<CurrentLibraryPort>(
      (Ref ref) => throw UnimplementedError(
        'currentLibraryPortProvider 未注入，请在 bootstrap 中 override',
      ),
    );

final Provider<LibraryReorderModePort> libraryReorderModePortProvider =
    Provider<LibraryReorderModePort>(
      (Ref ref) => throw UnimplementedError(
        'libraryReorderModePortProvider 未注入，请在 bootstrap 中 override',
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

final Provider<AsyncValue<CurrentLibraryState>> currentLibraryStateProvider =
    Provider<AsyncValue<CurrentLibraryState>>(
      (Ref ref) => throw UnimplementedError(
        'currentLibraryStateProvider 未注入，请在 bootstrap 中 override',
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

/// 系列详情入口（原 `seriesByIdProvider`，按 id 查询）。
final seriesByIdStateProvider = FutureProvider.family<Series?, String>(
  (Ref ref, String seriesId) => throw UnimplementedError(
    'seriesByIdStateProvider 未注入，请在 bootstrap 中 override',
  ),
);
