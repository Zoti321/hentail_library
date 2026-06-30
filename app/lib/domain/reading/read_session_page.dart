/// 阅读会话中的一页（领域层，不含 UI / IO 类型）。
sealed class ReadSessionPage {
  const ReadSessionPage();
}

final class ReadSessionDirPage extends ReadSessionPage {
  const ReadSessionDirPage(this.filePath);

  final String filePath;
}

final class ReadSessionArchivePage extends ReadSessionPage {
  const ReadSessionArchivePage({
    required this.comicId,
    required this.pageIndex,
  });

  final String comicId;
  final int pageIndex;
}
