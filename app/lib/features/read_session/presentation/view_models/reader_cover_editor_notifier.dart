import 'dart:typed_data';

import 'package:hentai_library/data/adapters/reader_frb_mapper.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/providers/comic_cover_providers.dart';
import 'package:hentai_library/ui/providers/series_cover_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reader_cover_editor_notifier.g.dart';

/// 阅读器内「设为封面」命令：以当前页（0-based）替换漫画 / 系列封面。
@Riverpod(keepAlive: true)
class ReaderCoverEditorNotifier extends _$ReaderCoverEditorNotifier {
  @override
  void build() {}

  Future<void> setComicCover(Comic comic, {required int pageIndex}) async {
    final repo = ref.read(comicThumbnailRepoProvider);
    await repo.setComicCoverFromPage(
      comicId: comic.comicId,
      path: comic.path,
      resourceType: mapResourceType(comic.resourceType),
      pageIndex: pageIndex,
    );
    final Uint8List? bytes = (await repo.findByComicId(
      comic.comicId,
    ))?.thumbnail;
    if (bytes != null && bytes.isNotEmpty) {
      ref
          .read(comicCoverThumbnailCacheProvider(comic.comicId).notifier)
          .set(bytes);
    }
  }

  Future<void> setSeriesCover(
    String seriesId,
    Comic comic, {
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
    ref.invalidate(seriesCoverSourceProvider(seriesId));
  }
}
