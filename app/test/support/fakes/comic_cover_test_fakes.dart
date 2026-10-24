import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/ui/models/comic_cover_state.dart';
import 'package:hentai_library/shared/di/comic_cover_providers.dart';

/// 固定状态的 [ComicCover]：不读仓库、不触发缩略图生成。
class FixedComicCover extends ComicCover {
  FixedComicCover(this._state);

  final ComicCoverState _state;

  @override
  ComicCoverState build(String comicId) => _state;

  @override
  void ensureLoaded({ThumbnailPriority priority = ThumbnailPriority.high}) {}
}
