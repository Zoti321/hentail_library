/// 由 comicId 派生的阅读器用系列上下文（ADR-0005）。
typedef SeriesReadingContext = ({
  String seriesId,
  String seriesName,
  List<String> orderedComicIds,
  int currentIndex,
});
