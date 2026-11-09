import 'dart:io';

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
