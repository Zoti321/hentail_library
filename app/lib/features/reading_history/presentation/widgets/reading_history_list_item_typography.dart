import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_catalog_card_shell.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Title line in [ReadingHistoryListItem] (aligned with catalog list rows).
TextStyle readingHistoryListItemTitleStyle(
  M3ETypeScale type,
  M3EColorScheme scheme,
) {
  return comicCatalogTitleStyle(type, scheme);
}

/// Page label (`current/total`) beside the progress bar.
TextStyle readingHistoryListItemProgressStyle(
  M3ETypeScale type,
  M3EColorScheme scheme,
) {
  return type.labelMedium.copyWith(
    fontWeight: FontWeight.w500,
    color: scheme.onSurfaceVariant,
    height: 1.2,
  );
}

/// Last-read date (secondary meta).
TextStyle readingHistoryListItemTimeStyle(
  M3ETypeScale type,
  M3EColorScheme scheme,
) {
  return comicCatalogSubtitleStyle(type, scheme);
}
