import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/features/comic_trash/domain/comic_trash_service.dart';
import 'package:hentai_library/shared/domain/models/read_models/trashed_comic.dart';
import 'package:hentai_library/features/comic_trash/di/comic_trash.dart';
import 'package:hentai_library/ui/features/shell/view_models/comic_metadata_bulk_patch_controller.dart';
import 'package:hentai_library/ui/features/shell/view_models/library_revision_notifier.dart';
import 'package:hentai_library/ui/features/shell/view_models/metadata_refresh_controller.dart';
import 'package:hentai_library/ui/features/shell/view_models/scan_library_controller.dart';
import 'package:hentai_library/ui/providers/comic_cover_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comic_trash_actions.g.dart';

const String kLibraryBusyMessage = '书库正在忙，请稍后再试';

/// Comic trash / restore / purge 的 UI 命令入口（ADR-0023）。
///
/// 书库同步、元数据刷新或批量编辑进行中时立即失败，不排队。
@Riverpod(keepAlive: true)
class ComicTrashActions extends _$ComicTrashActions {
  @override
  void build() {}

  ComicTrashService get _service => ref.read(comicTrashServiceProvider);

  Future<void> trash(List<String> comicIds) async {
    _ensureLibraryIdle();
    await _service.trashComics(comicIds);
    _notifyChanged();
  }

  Future<void> restore(List<String> comicIds) async {
    _ensureLibraryIdle();
    await _service.restoreComics(comicIds);
    _notifyChanged();
  }

  Future<int> restoreAll() async {
    _ensureLibraryIdle();
    final int restored = await _service.restoreAll();
    if (restored > 0) {
      _notifyChanged();
    }
    return restored;
  }

  Future<ComicPurgeResult> purge(List<String> comicIds) async {
    _ensureLibraryIdle();
    final ComicPurgeResult result = await _service.purgeComics(comicIds);
    await _afterPurge(comicIds, result);
    return result;
  }

  Future<ComicPurgeResult> purgeAll() async {
    _ensureLibraryIdle();
    final List<String> ids = await _service.listTrashedIds();
    final ComicPurgeResult result = await _service.purgeComics(ids);
    await _afterPurge(ids, result);
    return result;
  }

  Future<void> _afterPurge(
    List<String> requested,
    ComicPurgeResult result,
  ) async {
    if (result.succeeded > 0) {
      final Set<String> remaining = (await _service.listTrashedIds()).toSet();
      ref
          .read(comicCoverCacheManagerProvider.notifier)
          .clearForComics(
            requested.where((String id) => !remaining.contains(id)),
          );
    }
    _notifyChanged();
  }

  void _ensureLibraryIdle() {
    if (ref.read(scanLibraryControllerProvider).running ||
        ref.read(metadataRefreshControllerProvider).running ||
        ref.read(comicMetadataBulkPatchControllerProvider).running) {
      throw AppException(kLibraryBusyMessage);
    }
  }

  void _notifyChanged() {
    ref.read(libraryRevisionProvider.notifier).notifyExternalChange();
  }
}
