/// Lab 阅读画布状态（对应生产 read_session 的打开中 / 打开失败；静态预览用）。
enum Md3eReaderViewportStatus { ready, loading, error }

/// Lab 阅读页预览态（非 FRB Read session）。
class Md3eReaderPagePreviewData {
  const Md3eReaderPagePreviewData({
    required this.title,
    required this.totalPages,
    this.subtitle,
    this.initialPage = 1,
    this.currentVolumeId = 'vol-01',
    this.seriesVolumes = kMd3eReaderPreviewSeriesVolumes,
    this.viewportStatus = Md3eReaderViewportStatus.ready,
  });

  final String title;
  final String? subtitle;
  final int totalPages;
  final int initialPage;
  final String currentVolumeId;
  final List<Md3eReaderSeriesVolumePreview> seriesVolumes;
  final Md3eReaderViewportStatus viewportStatus;

  static Md3eReaderPagePreviewData sample() => const Md3eReaderPagePreviewData(
        title: '第 01 卷',
        subtitle: '葬送的芙莉莲',
        totalPages: 24,
        initialPage: 3,
      );
}

class Md3eReaderSeriesVolumePreview {
  const Md3eReaderSeriesVolumePreview({
    required this.id,
    required this.title,
  });

  final String id;
  final String title;
}

const List<Md3eReaderSeriesVolumePreview> kMd3eReaderPreviewSeriesVolumes =
    <Md3eReaderSeriesVolumePreview>[
  Md3eReaderSeriesVolumePreview(id: 'vol-01', title: '第 01 卷'),
  Md3eReaderSeriesVolumePreview(id: 'vol-02', title: '第 02 卷'),
  Md3eReaderSeriesVolumePreview(id: 'vol-03', title: '第 03 卷'),
];
