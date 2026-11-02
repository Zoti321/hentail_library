/// 由 comicId 派生的阅读器用系列上下文（ADR-0005）。
///
/// 真源 @ shared：library_browse series 仓储与 read_session 共用；勿经 feature 交叉 import。
typedef SeriesReadingContext = ({
  String seriesId,
  String seriesName,
  List<String> orderedComicIds,
  int currentIndex,
});
