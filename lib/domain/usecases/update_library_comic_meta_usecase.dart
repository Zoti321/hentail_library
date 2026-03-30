import 'package:hentai_library/domain/entity/comic/tag.dart';
import 'package:hentai_library/domain/enums/enums.dart';
import 'package:hentai_library/domain/repository/library_comic_repo.dart';

/// v2 用例壳：用户编辑覆盖解析值。
class UpdateLibraryComicMetaUseCase {
  final LibraryComicRepository repo;

  UpdateLibraryComicMetaUseCase(this.repo);

  Future<void> call(
    String comicId, {
    String? title,
    List<String>? authors,
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
