import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/ui/desktop/widgets/page/reader/reader_content_switcher.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ReaderContent extends ConsumerWidget {
  const ReaderContent({
    super.key,
    required this.comicId,
    required this.initialPage,
    required this.preferredPageIndex,
    required this.isVertical,
  });

  final String comicId;
  final int initialPage;
  final int? preferredPageIndex;
  final bool isVertical;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReaderContentSwitcher(
      comicId: comicId,
      initialPage: initialPage,
      preferredPageIndex: preferredPageIndex,
      isVertical: isVertical,
    );
  }
}
