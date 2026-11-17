import 'package:flutter/material.dart';
import 'package:hentai_library/features/reader/domain/reading_mode.dart';
import 'package:hentai_library/features/reader/presentation/view_models/reader_view_model.dart';
import 'package:hentai_library/features/reader/presentation/widgets/viewport/continuous_vertical_viewport.dart';
import 'package:hentai_library/features/reader/presentation/widgets/viewport/dual_page_viewport.dart';
import 'package:hentai_library/features/reader/presentation/widgets/viewport/paged_viewport.dart';

class ReaderViewportHost extends StatelessWidget {
  const ReaderViewportHost({
    super.key,
    required this.viewKey,
    required this.comicId,
    required this.incognito,
    this.startFromFirstPage = false,
    required this.initialPage,
    required this.preferredPageIndex,
    required this.readingMode,
    this.onRequestNextPage,
    this.onRequestPrevPage,
  });

  final ReaderViewModelKey viewKey;
  final String comicId;
  final bool incognito;
  final bool startFromFirstPage;
  final int initialPage;
  final int? preferredPageIndex;
  final ReadingMode readingMode;
  final Future<void> Function()? onRequestNextPage;
  final Future<void> Function()? onRequestPrevPage;

  @override
  Widget build(BuildContext context) {
    if (readingMode.isWebtoon) {
      return ContinuousVerticalViewport(
        viewKey: viewKey,
        comicId: comicId,
        preferredPageIndex: preferredPageIndex,
      );
    }
    if (readingMode.isDualPageMode) {
      return DualPageViewport(
        viewKey: viewKey,
        comicId: comicId,
        readingMode: readingMode,
        initialPage: initialPage,
        preferredPageIndex: preferredPageIndex,
        onRequestNextPage: onRequestNextPage,
        onRequestPrevPage: onRequestPrevPage,
      );
    }
    return PagedViewport(
      viewKey: viewKey,
      comicId: comicId,
      initialPage: initialPage,
      preferredPageIndex: preferredPageIndex,
      onRequestNextPage: onRequestNextPage,
      onRequestPrevPage: onRequestPrevPage,
    );
  }
}
