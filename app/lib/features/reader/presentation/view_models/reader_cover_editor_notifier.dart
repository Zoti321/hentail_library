import 'package:hentai_library/shared/presentation/providers/cover_command_providers.dart';
import 'package:hentai_library/features/reader/domain/reader_comic_ref.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reader_cover_editor_notifier.g.dart';

/// 阅读器内「设为封面」命令：当前页（0-based）替换漫画 / 系列封面。
///
/// 漫画封面写入真源在 `comic/application`（经 `comicCoverSetCommandProvider`）；
/// 系列封面与写后刷新由 series owner 承担，组合根绑定共享命令。
@Riverpod(keepAlive: true)
class ReaderCoverEditorNotifier extends _$ReaderCoverEditorNotifier {
  @override
  void build() {}

  Future<void> setComicCover(ReaderComicRef comic, {required int pageIndex}) {
    return ref.read(setComicCoverFromPageCommandProvider)(
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
  }) {
    return ref.read(setSeriesCoverFromPageCommandProvider)(
      seriesId: seriesId,
      comicId: comic.comicId,
      path: comic.path,
      resourceType: comic.resourceType,
      pageIndex: pageIndex,
    );
  }
}
