// 漫画排序类型
enum ComicSortType { title, lastUpdated, firstPublished, totalViews }

// 同步进度阶段
enum SyncPhase { collecting, scanning, applying }

// 扫描项类型（用于报告）
enum ScannedItemType { folder, epub, archive }

// 漫画图源类型
enum ComicImageSourceType {
  cbzcbr,
  zip,
  pdf,
  epub,
  folder;

  String get displayName {
    switch (this) {
      case ComicImageSourceType.cbzcbr:
        return 'CBZ/CBR';
      case ComicImageSourceType.zip:
        return 'ZIP';
      case ComicImageSourceType.pdf:
        return 'PDF';
      case ComicImageSourceType.epub:
        return 'EPUB';
      case ComicImageSourceType.folder:
        return '文件夹';
    }
  }
}
