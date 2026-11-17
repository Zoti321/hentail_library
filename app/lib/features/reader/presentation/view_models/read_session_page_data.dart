import 'dart:io';

import 'package:hentai_library/features/reader/domain/image_set_read_port.dart';

sealed class ReaderPageImageData {
  const ReaderPageImageData();

  int get archivePageIndex;
}

class ReaderDirPageImageData extends ReaderPageImageData {
  const ReaderDirPageImageData(this.file, {required this.pageIndex});

  final File file;
  final int pageIndex;

  @override
  int get archivePageIndex => pageIndex;
}

class ReaderArchivePageImageData extends ReaderPageImageData {
  const ReaderArchivePageImageData({
    required this.comicId,
    required this.pageIndex,
  });
  final String comicId;
  final int pageIndex;

  @override
  int get archivePageIndex => pageIndex;
}

class ReaderImageSetPageImageData extends ReaderPageImageData {
  const ReaderImageSetPageImageData({required this.page});

  final ImageSetReadPage page;

  String get sessionKey =>
      'image_set:${page.libraryId}:${page.imageSetId}';

  @override
  int get archivePageIndex => page.index;
}
