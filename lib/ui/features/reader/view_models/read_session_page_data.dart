import 'dart:io';

sealed class ReaderPageImageData {
  const ReaderPageImageData();
}

class ReaderDirPageImageData extends ReaderPageImageData {
  const ReaderDirPageImageData(this.file);
  final File file;
}

class ReaderArchivePageImageData extends ReaderPageImageData {
  const ReaderArchivePageImageData({
    required this.comicId,
    required this.pageIndex,
  });
  final String comicId;
  final int pageIndex;
}
