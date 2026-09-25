import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/domain/models/value_objects/series_item_membership.dart';
import 'package:hentai_library/ui/features/library/view_models/comic_metadata_apply.dart';
import 'package:hentai_library/ui/features/library/view_models/series_item_sort_persist.dart';
import 'package:hentai_library/ui/features/settings/view_models/metadata_auto_backup_coordinator_notifier.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/view_models/library_revision_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comic_metadata_editor_notifier.g.dart';

/// Comic 元数据编辑表面的命令入口：保存表单、字段锁与 Series 成员排序。
@Riverpod(keepAlive: true)
class ComicMetadataEditorNotifier extends _$ComicMetadataEditorNotifier {
  @override
  void build() {}

  Future<ComicMetadataApplyResult> apply(
    ComicMetadataForm form,
    Comic original,
  ) {
    return applyComicMetadataForm(
      ref.read(comicRepoProvider),
      form,
      original,
      invalidate: ref.invalidate,
      notifyExternalChange: _notifyExternalChange,
      notifyMetadataSavedForAutoBackup: () => ref
          .read(metadataAutoBackupCoordinatorProvider.notifier)
          .notifyMetadataSaved(),
    );
  }

  Future<void> setLocks(
    String comicId, {
    bool? title,
    bool? description,
    bool? publishedAt,
    bool? contentRating,
    bool? authors,
    bool? tags,
    bool? languages,
    bool? parodies,
    bool? characters,
  }) {
    return ref
        .read(comicRepoProvider)
        .setMetaLocks(
          comicId,
          title: title,
          description: description,
          publishedAt: publishedAt,
          contentRating: contentRating,
          authors: authors,
          tags: tags,
          languages: languages,
          parodies: parodies,
          characters: characters,
        );
  }

  Future<SeriesItemMembership?> findSeriesMembership(String comicId) {
    return ref.read(seriesRepoProvider).findMembershipByComicId(comicId);
  }

  Future<void> persistSeriesSort({
    required String comicId,
    required SeriesItemMembership seed,
    required double sortOrder,
    required bool draftLocked,
  }) async {
    final bool wrote = await persistSeriesItemSortIfChanged(
      repo: ref.read(seriesRepoProvider),
      comicId: comicId,
      seed: seed,
      sortOrder: sortOrder,
      draftLocked: draftLocked,
    );
    if (wrote) {
      _notifyExternalChange();
    }
  }

  void _notifyExternalChange() {
    ref.read(libraryRevisionProvider.notifier).notifyExternalChange();
  }
}
