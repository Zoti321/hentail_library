import 'package:hentai_library/features/comic_metadata/public.dart';
import 'package:hentai_library/features/reading_stats/domain/home_page_counts_repository.dart';
import 'package:hentai_library/infrastructure/frb/frb_call_guard.dart';
import 'package:hentai_library/features/reading_stats/domain/home_page_counts.dart';
import 'package:hentai_library/src/rust/api/home.dart' as rust;

class HomePageCountsRepositoryImpl implements HomePageCountsRepository {
  const HomePageCountsRepositoryImpl({
    required this.parodyRepository,
    required this.characterRepository,
  });

  final NamedFacetDictionaryRepository parodyRepository;
  final NamedFacetDictionaryRepository characterRepository;

  @override
  Stream<HomePageCounts> watchHomePageCounts({required bool excludeR18}) {
    return guardFrbStream(
      () => rust
          .watchHomePageCountsFrb(excludeR18: excludeR18)
          .asyncMap(_mapCounts),
      fallbackMessage: '读取首页统计失败',
    );
  }

  Future<HomePageCounts> _mapCounts(rust.HomePageCountsDto dto) async {
    final List<String> parodies = await parodyRepository.listAll();
    final List<String> characters = await characterRepository.listAll();
    return HomePageCounts(
      comicCount: dto.comicCount,
      tagCount: dto.tagCount,
      seriesCount: dto.seriesCount,
      authorCount: dto.authorCount,
      parodyCount: parodies.length,
      characterCount: characters.length,
      libraryCount: dto.libraryCount,
    );
  }
}
