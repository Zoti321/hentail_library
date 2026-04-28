import 'package:hentai_library/database/dao/dao.dart';
import 'package:hentai_library/model/enums.dart';

typedef AutoDetectComicContentRatingResult = ({
  int totalComics,
  int matchedComics,
  int updatedComics,
});

class AutoDetectComicContentRatingService {
  AutoDetectComicContentRatingService({
    required ComicDao comicDao,
    Set<String>? r18PathKeywords,
  }) : _comicDao = comicDao,
       _r18PathKeywords = (r18PathKeywords ?? _defaultR18PathKeywords)
           .map((String keyword) => keyword.trim().toLowerCase())
           .where((String keyword) => keyword.isNotEmpty)
           .toSet();

  static const Set<String> _defaultR18PathKeywords = <String>{
    '涩涩',
    '色情',
    'nsfw',
  };
  final ComicDao _comicDao;
  final Set<String> _r18PathKeywords;

  Future<AutoDetectComicContentRatingResult> executeAutoDetect() async {
    final List<({String comicId, String path})> comicIdAndPaths =
        await _comicDao.getAllComicIdAndPaths();
    if (comicIdAndPaths.isEmpty) {
      return (totalComics: 0, matchedComics: 0, updatedComics: 0);
    }

    final Set<String> matchedComicIds = <String>{};
    for (final ({String comicId, String path}) item in comicIdAndPaths) {
      if (_isR18Path(item.path)) {
        matchedComicIds.add(item.comicId);
      }
    }
    if (matchedComicIds.isEmpty) {
      return (
        totalComics: comicIdAndPaths.length,
        matchedComics: 0,
        updatedComics: 0,
      );
    }
    final int updatedComics = await _comicDao
        .batchUpdateContentRatingByComicIds(matchedComicIds, ContentRating.r18);
    return (
      totalComics: comicIdAndPaths.length,
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
