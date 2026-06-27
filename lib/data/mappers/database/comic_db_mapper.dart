import 'package:hentai_library/data/database/database.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';

class ComicDbMapper {
  const ComicDbMapper();
}

extension DbComicToEntity on DbComic {
  Comic toEntity({
    Iterable<String> authorNames = const <String>[],
    Iterable<String> tagNames = const <String>[],
  }) {
    return Comic(
      comicId: comicId,
      path: path,
      resourceType: resourceType,
      title: title,
      authors: authorNames.map((String n) => Author(name: n)).toList(),
      contentRating: contentRating,
      tags: tagNames.map((String n) => Tag(name: n)).toList(),
      pageCount: pageCount,
    );
  }
}
