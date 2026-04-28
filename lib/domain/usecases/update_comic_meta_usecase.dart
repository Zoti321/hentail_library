import 'package:hentai_library/model/entity/comic/author.dart';
import 'package:hentai_library/model/entity/comic/tag.dart';
import 'package:hentai_library/model/enums.dart';
import 'package:hentai_library/domain/repository/comic_repo.dart';

/// 用例壳：用户编辑覆盖解析值。
class UpdateComicMetaUseCase {
  final ComicRepository repo;

  UpdateComicMetaUseCase(this.repo);

  Future<void> call(
    String comicId, {
    String? title,
    List<Author>? authors,
    ContentRating? contentRating,
    List<Tag>? tags,
  }) {
    return repo.updateUserMeta(
      comicId,
      title: title,
      authors: authors,
      contentRating: contentRating,
      tags: tags,
    );
  }
}
