/// 单本漫画用于标题映射的输入。
final class ComicTitleInput {
  const ComicTitleInput({required this.comicId, required this.title});

  final String comicId;
  final String title;
}

/// 将漫画标题解析为系列名与卷序，供后续写入 [SeriesItem] 的排序依据（无 I/O）。
final class ComicTitleToSeriesItemMapping {
  const ComicTitleToSeriesItemMapping();

  static final RegExp _volumeSuffixPattern = RegExp(r'^(.+?)\s+(\d+)$');
  static final RegExp _zenpenKouhenPattern = RegExp(r'^(.+?)\s+(前篇|后篇)$');

  /// 若标题符合「基名 + 空白 + 正整数卷号」，或「基名 + 空白 + 前篇/后篇」，返回系列名与卷序；否则返回 null。
  /// 前篇、后篇分别映射为卷序 1、2（前篇先于后篇）。
  ({String seriesName, int volumeIndex})? mapComicTitleToSeriesVolume(
    String title,
  ) {
    final String trimmed = title.trim();
    final Match? digitMatch = _volumeSuffixPattern.firstMatch(trimmed);

    if (digitMatch != null) {
      final String baseName = digitMatch.group(1)!.trim();
      if (baseName.isEmpty) {
        return null;
      }
      final int volumeIndex = int.parse(digitMatch.group(2)!);
      if (volumeIndex < 1) {
        return null;
      }
      return (seriesName: baseName, volumeIndex: volumeIndex);
    }

    final Match? zkMatch = _zenpenKouhenPattern.firstMatch(trimmed);
    if (zkMatch == null) {
      return null;
    }
    final String baseName = zkMatch.group(1)!.trim();
    if (baseName.isEmpty) {
      return null;
    }
    final String part = zkMatch.group(2)!;
    final int volumeIndex = part == '前篇' ? 1 : 2;
    return (seriesName: baseName, volumeIndex: volumeIndex);
  }
}
