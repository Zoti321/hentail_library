import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';

typedef AutoDetectComicContentRatingResult = ({
  int totalComics,
  int matchedComics,
  int updatedComics,
});

class AutoDetectComicContentRatingService {
  AutoDetectComicContentRatingService({
    required ComicRepository comicRepository,
    Set<String>? r18PathKeywords,
  }) : _comicRepository = comicRepository,
       _r18PathKeywords = (r18PathKeywords ?? _defaultR18PathKeywords)
           .map((String keyword) => keyword.trim().toLowerCase())
           .where((String keyword) => keyword.isNotEmpty)
           .toSet();

  static const Set<String> _defaultR18PathKeywords = <String>{
    '涩涩',
    '色情',
    'nsfw',
  };
  final ComicRepository _comicRepository;
  final Set<String> _r18PathKeywords;

  Future<AutoDetectComicContentRatingResult> executeAutoDetect() async {
    final List<Comic> comics = await _comicRepository.getAll();
    if (comics.isEmpty) {
      return (totalComics: 0, matchedComics: 0, updatedComics: 0);
    }

    final Set<String> matchedComicIds = <String>{};
    for (final Comic comic in comics) {
      if (_isR18Path(comic.path)) {
        matchedComicIds.add(comic.comicId);
      }
    }
    if (matchedComicIds.isEmpty) {
      return (
        totalComics: comics.length,
        matchedComics: 0,
        updatedComics: 0,
      );
    }

    var updatedComics = 0;
    for (final String comicId in matchedComicIds) {
      final Comic comic = comics.firstWhere((Comic c) => c.comicId == comicId);
      if (comic.contentRating == ContentRating.r18) {
        continue;
      }
      await _comicRepository.updateUserMeta(
        comicId,
        contentRating: ContentRating.r18,
      );
      updatedComics++;
    }
    return (
      totalComics: comics.length,
      matchedComics: matchedComicIds.length,
      updatedComics: updatedComics,
    );
  }

  bool _isR18Path(String path) {
    final String normalizedPath = path.toLowerCase();
    for (final String keyword in _r18PathKeywords) {
      if (normalizedPath.contains(keyword)) {
        return true;
      }
    }
    return false;
  }
}
