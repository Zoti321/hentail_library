/// Home page counts：跨库库存聚合读模型（非 Reading activity stats）。
///
/// Comic / Series / Author / Parody / Character / Tag；
/// [libraryCount] 为库数量附属字段（非库存卡六计数之一）。
class HomePageCounts {
  const HomePageCounts({
    required this.comicCount,
    required this.tagCount,
    required this.seriesCount,
    required this.authorCount,
    required this.parodyCount,
    required this.characterCount,
    required this.libraryCount,
  });

  final int comicCount;
  final int tagCount;
  final int seriesCount;
  final int authorCount;
  final int parodyCount;
  final int characterCount;
  final int libraryCount;

  HomePageCounts copyWith({
    int? comicCount,
    int? tagCount,
    int? seriesCount,
    int? authorCount,
    int? parodyCount,
    int? characterCount,
    int? libraryCount,
  }) {
    return HomePageCounts(
      comicCount: comicCount ?? this.comicCount,
      tagCount: tagCount ?? this.tagCount,
      seriesCount: seriesCount ?? this.seriesCount,
      authorCount: authorCount ?? this.authorCount,
      parodyCount: parodyCount ?? this.parodyCount,
      characterCount: characterCount ?? this.characterCount,
      libraryCount: libraryCount ?? this.libraryCount,
    );
  }
}
