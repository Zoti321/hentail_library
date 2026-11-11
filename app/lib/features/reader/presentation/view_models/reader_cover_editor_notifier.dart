import 'package:hentai_library/features/comic/public.dart';
import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/di/series_slot_providers.dart';
import 'package:hentai_library/shared/domain/models/resource_type_frb_wire.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reader_cover_editor_notifier.g.dart';

/// 阅读器内「设为封面」命令：当前页（0-based）替换漫画 / 系列封面。
///
/// 漫画封面写入真源在 `comic/application`（经 `comicCoverSetCommandProvider`）；
/// 系列封面仍由 series owner 承担；失效经 shared/di 槽位，reader 不依赖 series（#493）。
@Riverpod(keepAlive: true)
class ReaderCoverEditorNotifier extends _$ReaderCoverEditorNotifier {
  @override
  void build() {}

  Future<void> setComicCover(ReaderComicRef comic, {required int pageIndex}) {
    return ref.read(comicCoverSetCommandProvider)(
      comicId: comic.comicId,
      path: comic.path,
      resourceType: comic.resourceType,
      pageIndex: pageIndex,
    );
  }

  Future<void> setSeriesCover(
    String seriesId,
    ReaderComicRef comic, {
    required int pageIndex,
  }) async {
    await ref
        .read(comicThumbnailRepoProvider)
        .setSeriesCoverFromPage(
          seriesId: seriesId,
          comicId: comic.comicId,
          path: comic.path,
          resourceType: mapResourceType(comic.resourceType),
          pageIndex: pageIndex,
        );
    ref.read(seriesCoverInvalidationSlotProvider)(seriesId);
  }
}
