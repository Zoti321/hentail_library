import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/ports/library_reorder_mode_port.dart';
import 'package:hentai_library/shared/di/injected_di.dart';
import 'package:hentai_library/shared/domain/library/comic_detail_return_series_port.dart';
import 'package:hentai_library/shared/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/shared/domain/library/library_revision_state.dart';

/// 跨 feature 共享的库状态与端口 Provider 声明（#261a）。
///
/// 实现与 `createX…Port` 工厂见 owner
/// `features/library_admin/public.dart`（bootstrap override 注入）。
/// library_admin 自己的状态投影见 `features/library_admin/public/di/library_admin_state_providers.dart`。

final Provider<LibraryReorderModePort> libraryReorderModePortProvider =
    injectedDi('libraryReorderModePortProvider');

final Provider<bool> libraryReorderActiveStateProvider = injectedDi(
  'libraryReorderActiveStateProvider',
);

/// 导出当前库元数据：实现位于 metadata_backup，由 bootstrap 注入，library_browse 不直接依赖 metadata_backup。
final Provider<Future<void> Function(BuildContext context, String libraryId)>
libraryMetadataExportActionProvider = injectedDi(
  'libraryMetadataExportActionProvider',
);

final Provider<ComicDetailReturnSeriesPort>
comicDetailReturnSeriesPortProvider = injectedDi(
  'comicDetailReturnSeriesPortProvider',
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
