import 'package:flutter/material.dart';
import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/continuous_vertical_viewport.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/dual_page_viewport.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/paged_viewport.dart';

class ReaderViewportHost extends StatelessWidget {
  const ReaderViewportHost({
    super.key,
    required this.comicId,
    required this.incognito,
    required this.initialPage,
    required this.preferredPageIndex,
    required this.readingMode,
    this.onRequestNextPage,
  });

  final String comicId;
  final bool incognito;
  final int initialPage;
  final int? preferredPageIndex;
  final ReadingMode readingMode;
  final Future<void> Function()? onRequestNextPage;

  @override
  Widget build(BuildContext context) {
    if (readingMode.isWebtoon) {
      return ContinuousVerticalViewport(
        comicId: comicId,
        incognito: incognito,
        preferredPageIndex: preferredPageIndex,
      );
    }
    if (readingMode.isDualPageMode) {
      return DualPageViewport(
        comicId: comicId,
        incognito: incognito,
        readingMode: readingMode,
        initialPage: initialPage,
        preferredPageIndex: preferredPageIndex,
        onRequestNextPage: onRequestNextPage,
      );
    }
    return PagedViewport(
      comicId: comicId,
      incognito: incognito,
      initialPage: initialPage,
      preferredPageIndex: preferredPageIndex,
      onRequestNextPage: onRequestNextPage,
    );
  }
}
