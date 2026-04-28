class MetadataIoPayload {
  const MetadataIoPayload({
    required this.authors,
    required this.tags,
    required this.series,
  });

  final List<String> authors;
  final List<String> tags;
  final List<MetadataIoSeries> series;

  Map<String, Object> toJson() {
    return <String, Object>{
      'authors': authors,
      'tags': tags,
      'series': series.map((MetadataIoSeries value) => value.toJson()).toList(),
    };
  }
}

class MetadataImportReport {
  const MetadataImportReport({
    required this.addedAuthors,
    required this.skippedAuthors,
    required this.addedTags,
    required this.skippedTags,
    required this.addedSeries,
    required this.skippedSeries,
    required this.writtenSeriesItems,
    required this.skippedSeriesItemsMissingComic,
    required this.skippedSeriesItemsOccupied,
    required this.skippedSeriesItemsOrderConflict,
  });

  final int addedAuthors;
  final int skippedAuthors;
  final int addedTags;
  final int skippedTags;
  final int addedSeries;
  final int skippedSeries;
  final int writtenSeriesItems;
  final int skippedSeriesItemsMissingComic;
  final int skippedSeriesItemsOccupied;
  final int skippedSeriesItemsOrderConflict;
}

class MetadataIoSeries {
  const MetadataIoSeries({required this.name, required this.items});

  final String name;
  final List<MetadataIoSeriesItem> items;

  Map<String, Object> toJson() {
    return <String, Object>{
      'name': name,
      'items': items.map((MetadataIoSeriesItem value) => value.toJson()).toList(),
    };
  }
}

class MetadataIoSeriesItem {
  const MetadataIoSeriesItem({required this.comicTitle, required this.order});

  final String comicTitle;
  final int order;

  Map<String, Object> toJson() {
    return <String, Object>{'comicTitle': comicTitle, 'order': order};
  }
}

