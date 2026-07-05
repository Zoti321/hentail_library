import 'package:flutter/material.dart';
import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/ui/features/reader/module/view/reader_viewport_host.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ReaderContent extends ConsumerWidget {
  const ReaderContent({
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
  Widget build(BuildContext context, WidgetRef ref) {
    return ReaderViewportHost(
      comicId: comicId,
      incognito: incognito,
      initialPage: initialPage,
      preferredPageIndex: preferredPageIndex,
      readingMode: readingMode,
      onRequestNextPage: onRequestNextPage,
    );
  }
}
