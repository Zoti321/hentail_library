import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/ui/core/widgets/pagination/library_pagination_bar.dart';
import 'package:hentai_library/ui/features/library/view_models/series_detail_comics_catalog_controller.dart';

class SeriesDetailPaginationBar extends ConsumerWidget {
  const SeriesDetailPaginationBar({
    super.key,
    required this.seriesId,
    required this.page,
    required this.totalPages,
    this.placement = LibraryPaginationPlacement.bottom,
  });

  final String seriesId;
  final int page;
  final int totalPages;
  final LibraryPaginationPlacement placement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LibraryPaginationBar(
      page: page,
      totalPages: totalPages,
      placement: placement,
      onJump: ref
          .read(seriesDetailComicsCatalogControllerProvider(seriesId).notifier)
          .jump,
    );
  }
}
