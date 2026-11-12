import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_admin/domain/bulk_edit_comic_metadata_command.dart';
import 'package:hentai_library/features/library_admin/domain/library_commands.dart';
import 'package:hentai_library/features/library_admin/domain/libraries_state.dart';
import 'package:hentai_library/features/library_admin/domain/library_metadata_refresh_commands.dart';
import 'package:hentai_library/features/library_admin/domain/library_repository.dart';
import 'package:hentai_library/features/library_admin/domain/library_scan_activity_state.dart';
import 'package:hentai_library/features/library_admin/domain/library_revision_state.dart';
import 'package:hentai_library/features/library_admin/domain/library_scan_commands.dart';
import 'package:hentai_library/features/library_admin/presentation/contracts/library_management_commands.dart';
import 'package:hentai_library/shared/presentation/providers/required_provider.dart';

/// library_admin 拥有的库状态投影 token（#513，ADR-0045）。
///
/// 实现与 `createX…` 工厂见 owner `features/library_admin/public.dart`，
/// 由 bootstrap 的 shared-state overrides 注入。

final Provider<AsyncValue<LibrariesState>> librariesStateProvider =
    requiredProvider('librariesStateProvider');

/// Catalog 刷新计数投影（生产者 owner，ADR-0045；原 @ `shared/di`）。
final Provider<LibraryRevisionState> libraryRevisionStateProvider =
    requiredProvider('libraryRevisionStateProvider');

final Provider<LibraryScanActivityState> libraryScanActivityStateProvider =
    requiredProvider('libraryScanActivityStateProvider');

/// library_admin 扫描是否进行中（原 `scanLibraryControllerProvider.running`）。
final Provider<bool> libraryScanRunningStateProvider = requiredProvider(
  'libraryScanRunningStateProvider',
);

final Provider<bool> libraryMetadataRefreshRunningStateProvider =
    requiredProvider('libraryMetadataRefreshRunningStateProvider');

/// 正在做「单库」元数据刷新时该库的 libraryId；否则为 null（列表行 busy 态用）。
final Provider<String?> libraryMetadataRefreshTargetLibraryIdStateProvider =
    requiredProvider('libraryMetadataRefreshTargetLibraryIdStateProvider');

/// 书库是否处于变更型后台任务中（扫描 / 元数据刷新 / 批量编辑任一运行），供 trash 等命令门控。
final Provider<bool> libraryMutationBusyStateProvider = requiredProvider(
  'libraryMutationBusyStateProvider',
);

final Provider<BulkEditComicMetadataCommand>
bulkEditComicMetadataCommandProvider = requiredProvider(
  'bulkEditComicMetadataCommandProvider',
);

final Provider<LibraryRepository> libraryRepoProvider = requiredProvider(
  'libraryRepoProvider',
);

final Provider<DeleteLibraryCommand> deleteLibraryCommandProvider =
    requiredProvider('deleteLibraryCommandProvider');
final Provider<UpdateLibrarySidebarCommand>
updateLibrarySidebarCommandProvider = requiredProvider(
  'updateLibrarySidebarCommandProvider',
);
final Provider<SubmitLibraryFormCommand> submitLibraryFormCommandProvider =
    requiredProvider('submitLibraryFormCommandProvider');

final Provider<StartLibraryScanCommand> startLibraryScanCommandProvider =
    requiredProvider('startLibraryScanCommandProvider');
final Provider<CancelLibraryScanCommand> cancelLibraryScanCommandProvider =
    requiredProvider('cancelLibraryScanCommandProvider');

/// 全量库管理 UI 命令 token（真源 @ library_admin，ADR-0045）。
///
/// `shared/**` 不消费本 token；它只读 `shared/di` 的
/// `goLibraryBrowseFallbackCommandProvider` 窄口。
final Provider<LibraryManagementCommands> libraryManagementCommandsProvider =
    requiredProvider('libraryManagementCommandsProvider');

/// 单库 / 全库元数据刷新命令口 token。
final Provider<RefreshComicMetadataCommand>
refreshComicMetadataCommandProvider = requiredProvider(
  'refreshComicMetadataCommandProvider',
);
final Provider<RefreshSeriesMetadataCommand>
refreshSeriesMetadataCommandProvider = requiredProvider(
  'refreshSeriesMetadataCommandProvider',
);
final Provider<RefreshLibraryMetadataCommand>
refreshLibraryMetadataCommandProvider = requiredProvider(
  'refreshLibraryMetadataCommandProvider',
);
final Provider<CancelMetadataRefreshCommand>
cancelMetadataRefreshCommandProvider = requiredProvider(
  'cancelMetadataRefreshCommandProvider',
);
