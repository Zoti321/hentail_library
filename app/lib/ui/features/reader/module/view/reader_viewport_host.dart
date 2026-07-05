import 'package:flutter/material.dart';
import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/ui/features/reader/module/widgets/viewport/paged_viewport.dart';
import 'package:hentai_library/ui/features/reader/views/desktop/reader_page/widgets/reader_vertical_content.dart';

class ReaderViewportHost extends StatelessWidget {
  const ReaderViewportHost({
    super.key,
    required this.comicId,
    required this.incognito,
    required this.initialPage,
    required this.preferredPageIndex,
    required this.readingMode,
  });

  final String comicId;
  final bool incognito;
  final int initialPage;
  final int? preferredPageIndex;
  final ReadingMode readingMode;

  @override
  Widget build(BuildContext context) {
    if (readingMode.effectiveViewportMode.isContinuousVertical) {
      return ReaderVerticalContent(
        comicId: comicId,
        incognito: incognito,
        preferredPageIndex: preferredPageIndex,
      );
    }
    return PagedViewport(
      comicId: comicId,
      incognito: incognito,
      initialPage: initialPage,
      preferredPageIndex: preferredPageIndex,
    );
  }
}
