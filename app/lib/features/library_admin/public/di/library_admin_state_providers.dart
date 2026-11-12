import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_admin/domain/comic_metadata_bulk_edit_command_port.dart';
import 'package:hentai_library/features/library_admin/domain/libraries_port.dart';
import 'package:hentai_library/features/library_admin/domain/libraries_state.dart';
import 'package:hentai_library/features/library_admin/domain/library_metadata_refresh_command_port.dart';
import 'package:hentai_library/features/library_admin/domain/library_repository.dart';
import 'package:hentai_library/features/library_admin/domain/library_scan_activity_state.dart';
import 'package:hentai_library/features/library_admin/domain/library_revision_state.dart';
import 'package:hentai_library/features/library_admin/domain/library_scan_command_port.dart';
import 'package:hentai_library/shared/di/injected_di.dart';

/// library_admin 拥有的库状态投影 token（#513，ADR-0045）。
///
/// 实现与 `createX…` 工厂见 owner `features/library_admin/public.dart`，
/// 由 bootstrap 的 shared-state overrides 注入。

final Provider<AsyncValue<LibrariesState>> librariesStateProvider = injectedDi(
  'librariesStateProvider',
);

/// Catalog 刷新计数投影（生产者 owner，ADR-0045；原 @ `shared/di`）。
final Provider<LibraryRevisionState> libraryRevisionStateProvider = injectedDi(
  'libraryRevisionStateProvider',
);

final Provider<LibraryScanActivityState> libraryScanActivityStateProvider =
    injectedDi('libraryScanActivityStateProvider');

/// library_admin 扫描是否进行中（原 `scanLibraryControllerProvider.running`）。
final Provider<bool> libraryScanRunningStateProvider = injectedDi(
  'libraryScanRunningStateProvider',
);

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

final Provider<ComicMetadataBulkEditCommandPort>
comicMetadataBulkEditCommandPortProvider = injectedDi(
  'comicMetadataBulkEditCommandPortProvider',
);

final Provider<LibraryRepository> libraryRepoProvider = injectedDi(
  'libraryRepoProvider',
);

final Provider<LibrariesPort> librariesPortProvider = injectedDi(
  'librariesPortProvider',
);

final Provider<LibraryScanCommandPort> libraryScanCommandPortProvider =
    injectedDi('libraryScanCommandPortProvider');

/// 单库 / 全库元数据刷新命令口 token。
final Provider<LibraryMetadataRefreshCommandPort>
libraryMetadataRefreshCommandPortProvider = injectedDi(
  'libraryMetadataRefreshCommandPortProvider',
);
