/// library_browse 拥有的缩略图后台进度；经 shared 转发，避免 library_admin ↔ library_browse public 成环。
library;

export 'package:hentai_library/features/library_browse/di/comic_cover_providers.dart'
    show ThumbnailBackgroundProgress, thumbnailEventCoordinatorProvider;
