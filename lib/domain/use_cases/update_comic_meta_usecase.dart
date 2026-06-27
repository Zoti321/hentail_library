import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/data/repositories/comic_repository.dart';

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
