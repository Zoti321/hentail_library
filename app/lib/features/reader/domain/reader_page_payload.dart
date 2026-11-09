import 'dart:typed_data';

/// 归档页已解析的像素来源（领域层，不含 FRB 类型）。
sealed class ReaderPagePayload {
  const ReaderPagePayload();
}

final class ReaderPageFilePath extends ReaderPagePayload {
  const ReaderPageFilePath(this.path);

  final String path;
}

final class ReaderPageBytes extends ReaderPagePayload {
  const ReaderPageBytes(this.data);

  final Uint8List data;
}
