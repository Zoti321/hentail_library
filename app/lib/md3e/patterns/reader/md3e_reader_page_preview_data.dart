/// Lab 阅读页预览态（非 FRB Read session）。
class Md3eReaderPagePreviewData {
  const Md3eReaderPagePreviewData({
    required this.title,
    required this.totalPages,
    this.subtitle,
    this.initialPage = 1,
  });

  final String title;
  final String? subtitle;
  final int totalPages;
  final int initialPage;

  static Md3eReaderPagePreviewData sample() => const Md3eReaderPagePreviewData(
        title: '第 01 卷',
        subtitle: '葬送的芙莉莲',
        totalPages: 24,
        initialPage: 3,
      );
}
