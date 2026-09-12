import 'package:flutter/material.dart';
import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/ui/features/reader/module/view/reader_viewport_host.dart';

class ReaderContent extends StatelessWidget {
  const ReaderContent({
    super.key,
    required this.comicId,
    required this.incognito,
    this.startFromFirstPage = false,
    required this.initialPage,
    required this.preferredPageIndex,
    required this.readingMode,
    this.onRequestNextPage,
    this.onRequestPrevPage,
  });

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
    // Mode switches swap viewports immediately — no AnimatedSwitcher overlap (P2-9).
    return ReaderViewportHost(
      key: ValueKey<ReadingMode>(readingMode),
      comicId: comicId,
      incognito: incognito,
      startFromFirstPage: startFromFirstPage,
      initialPage: initialPage,
      preferredPageIndex: preferredPageIndex,
      readingMode: readingMode,
      onRequestNextPage: onRequestNextPage,
      onRequestPrevPage: onRequestPrevPage,
    );
  }
}
