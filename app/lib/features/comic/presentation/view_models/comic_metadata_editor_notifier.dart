import 'package:hentai_library/features/comic/application/comic_metadata_service.dart';
import 'package:hentai_library/features/comic/public/di/comic_repository_providers.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/value_objects/form/comic_metadata_form.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_item_membership.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/di/library_change_bus.dart';
import 'package:hentai_library/shared/di/library_state_providers.dart';
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
      ref.read(comicUserMetadataRepositoryProvider),
      form,
      original,
      notifyExternalChange: _notifyExternalChange,
      publish: ref.read(libraryChangeBusProvider.notifier).publish,
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
        .read(comicUserMetadataRepositoryProvider)
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
    final bool wrote = await _persistSeriesItemSortIfChanged(
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
    ref.read(libraryRevisionSignalPortProvider).notifyExternalChange();
  }
}

Future<bool> _persistSeriesItemSortIfChanged({
  required dynamic repo,
  required String comicId,
  required SeriesItemMembership seed,
  required double sortOrder,
  required bool draftLocked,
}) async {
  final bool orderChanged = sortOrder != seed.sortOrder;
  final bool lockChanged = draftLocked != seed.sortOrderLocked;
  if (!orderChanged && !lockChanged) {
    return false;
  }

  if (orderChanged) {
    await repo.updateSeriesItemSortOrder(
      seriesId: seed.seriesId,
      comicId: comicId,
      sortOrder: sortOrder,
    );
  } else if (lockChanged) {
    await repo.setSeriesItemSortOrderLocked(
      seriesId: seed.seriesId,
      comicId: comicId,
      locked: draftLocked,
    );
  }
  return true;
}
