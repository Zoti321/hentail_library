import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/page/reader/reader_paged_content.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/page/reader/reader_vertical_content.dart';

class ReaderContentSwitcher extends StatelessWidget {
  const ReaderContentSwitcher({
    super.key,
    required this.comicId,
    required this.initialPage,
    required this.preferredPageIndex,
    required this.isVertical,
    this.verticalChild,
    this.pagedChild,
  });
  final String comicId;
  final int initialPage;
  final int? preferredPageIndex;
  final bool isVertical;
  final Widget? verticalChild;
  final Widget? pagedChild;

  @override
  Widget build(BuildContext context) {
    if (isVertical) {
      final Widget? overrideVerticalChild = verticalChild;
      if (overrideVerticalChild != null) {
        return overrideVerticalChild;
      }
      return ReaderVerticalContent(
        comicId: comicId,
        preferredPageIndex: preferredPageIndex,
      );
    }
    final Widget? overridePagedChild = pagedChild;
    if (overridePagedChild != null) {
      return overridePagedChild;
    }
    return ReaderPagedContent(
      comicId: comicId,
      initialPage: initialPage,
      preferredPageIndex: preferredPageIndex,
    );
  }
}
