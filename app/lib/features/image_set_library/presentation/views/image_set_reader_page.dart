import 'package:flutter/material.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_entry.dart';
import 'package:hentai_library/features/reader/public.dart';

/// 将 Image set Reader 压入根 Navigator；退出即 pop 回图集详情。
void pushImageSetReaderPage(
  NavigatorState? navigator,
  ImageSetReaderEntry entry,
) {
  navigator?.push(
    MaterialPageRoute<void>(
      builder: (_) => ImageSetReaderPage(entry: entry),
    ),
  );
}

/// Image set 阅读页：复用生产 [ReaderPage] 会话/视口；不写 Comic 历史。
class ImageSetReaderPage extends StatelessWidget {
  const ImageSetReaderPage({super.key, required this.entry});

  final ImageSetReaderEntry entry;

  @override
  Widget build(BuildContext context) {
    return ReaderPage.forSource(
      source: ImageSetReadSessionSource(
        libraryId: entry.libraryId,
        imageSetId: entry.imageSetId,
        startIndex: entry.index,
      ),
    );
  }
}
