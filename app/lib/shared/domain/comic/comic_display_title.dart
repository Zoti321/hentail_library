import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/repositories/comic_repository.dart';

String comicTitleFallbackForDisplay(String comicId) {
  return comicId.length > 12 ? '${comicId.substring(0, 12)}…' : comicId;
}

Future<String> resolveComicTitleForDisplay(
  ComicRepository repo,
  String comicId,
) async {
  final Map<String, String> titles = await resolveComicTitlesForDisplay(
    repo,
    <String>[comicId],
  );
  return titles[comicId] ?? comicTitleFallbackForDisplay(comicId);
}

Future<Map<String, String>> resolveComicTitlesForDisplay(
  ComicRepository repo,
  List<String> comicIds,
) async {
  if (comicIds.isEmpty) {
    return const <String, String>{};
  }
  final List<Comic> comics = await repo.findByIds(comicIds);
  final Map<String, String> titlesById = <String, String>{
    for (final Comic comic in comics) comic.comicId: comic.title,
  };
  return <String, String>{
    for (final String comicId in comicIds)
      comicId: titlesById[comicId] ?? comicTitleFallbackForDisplay(comicId),
  };
}
