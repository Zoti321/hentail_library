import 'package:hentai_library/features/comic/application/comic_metadata_service.dart';
import 'package:hentai_library/features/comic/di/comic_metadata_service.dart';
import 'package:hentai_library/shared/di/series_item_membership_providers.dart';
import 'package:hentai_library/shared/di/series_item_sort_providers.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/features/comic/domain/value_objects/comic_metadata_form.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_item_membership.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hentai_library/features/comic/di/comic_repository_providers.dart';

part 'comic_metadata_editor_notifier.g.dart';

/// Comic 元数据编辑表面的命令入口：保存表单、字段锁与 Series 成员排序。
@Riverpod(keepAlive: true)
class ComicMetadataEditorNotifier extends _$ComicMetadataEditorNotifier {
  @override
  void build() {}

  Future<ComicMetadataApplyResult> apply(
    ComicMetadataForm form,
    Comic original,
  ) => ref.read(comicMetadataApplyCommandProvider)(form, original);

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
    return ref
        .read(seriesItemMembershipPortProvider)
        .findMembershipByComicId(comicId);
  }

  Future<void> persistSeriesSort({
    required String comicId,
    required SeriesItemMembership seed,
    required double sortOrder,
    required bool draftLocked,
  }) async {
    await ref
        .read(seriesItemSortPortProvider)
        .persistIfChanged(
          comicId: comicId,
          seed: seed,
          sortOrder: sortOrder,
          draftLocked: draftLocked,
        );
  }
}
