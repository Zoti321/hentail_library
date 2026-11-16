import 'package:hentai_library/features/comic/application/comic_metadata_service.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/features/comic/domain/value_objects/comic_metadata_form.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_item_membership.dart';
import 'package:hentai_library/shared/application/contracts/persist_series_item_sort_command.dart';

typedef ApplyComicMetadata = Future<ComicMetadataApplyResult> Function(
  ComicMetadataForm form,
  Comic original,
);
typedef ComicSeriesSortRequest = ({
  SeriesItemMembership seed,
  double sortOrder,
  bool draftLocked,
});

/// 保存元数据后再提交可选系列排序。
///
/// 排序失败时元数据可能已提交；异常向上传播，不补偿或重试第一步。
class SaveComicMetadataUseCase {
  const SaveComicMetadataUseCase({
    required this.apply,
    required this.persistSort,
  });
  final ApplyComicMetadata apply;
  final PersistSeriesItemSortCommand persistSort;

  Future<ComicMetadataApplyResult> call(
    ComicMetadataForm form,
    Comic original, {
    ComicSeriesSortRequest? sort,
  }) async {
    final result = await apply(form, original);
    if (result is ComicMetadataApplySucceeded && sort != null) {
      await persistSort(
        comicId: original.comicId,
        seed: sort.seed,
        sortOrder: sort.sortOrder,
        draftLocked: sort.draftLocked,
      );
    }
    return result;
  }
}
