/// 系列内漫画聚合元数据（作者、标签、R18）。
class SeriesComicsMetadata {
  const SeriesComicsMetadata({
    required this.authors,
    required this.tags,
    required this.hasR18,
  });

  final List<String> authors;
  final List<String> tags;
  final bool hasR18;

  bool get hasMetadataBlock => authors.isNotEmpty || tags.isNotEmpty;
}
