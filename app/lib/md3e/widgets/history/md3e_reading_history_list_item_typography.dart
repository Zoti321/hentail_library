import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/widgets/catalog/md3e_comic_catalog_card_shell.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Title line in [Md3eReadingHistoryListItem] (aligned with catalog list rows).
TextStyle md3eReadingHistoryListItemTitleStyle(
  M3ETypeScale type,
  M3EColorScheme scheme,
) {
  return md3eComicCatalogTitleStyle(type, scheme);
}

/// Page progress (`current/total`) — accent via [M3EColorScheme.primary].
TextStyle md3eReadingHistoryListItemProgressStyle(
  M3ETypeScale type,
  M3EColorScheme scheme,
) {
  return type.labelLarge.copyWith(
    fontWeight: FontWeight.w500,
    color: scheme.primary,
    height: 1.2,
  );
}

/// Relative last-read time (secondary meta).
TextStyle md3eReadingHistoryListItemTimeStyle(
  M3ETypeScale type,
  M3EColorScheme scheme,
) {
  return md3eComicCatalogSubtitleStyle(type, scheme);
}
