import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_series_volume.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_viewport_status.dart';

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
  final List<Md3eReaderSeriesVolume> seriesVolumes;
  final Md3eReaderViewportStatus viewportStatus;

  static Md3eReaderPagePreviewData sample() => const Md3eReaderPagePreviewData(
    title: '第 01 卷',
    subtitle: '葬送的芙莉莲',
    totalPages: 24,
    initialPage: 3,
  );
}

const List<Md3eReaderSeriesVolume> kMd3eReaderPreviewSeriesVolumes =
    <Md3eReaderSeriesVolume>[
      Md3eReaderSeriesVolume(id: 'vol-01', title: '第 01 卷'),
      Md3eReaderSeriesVolume(id: 'vol-02', title: '第 02 卷'),
      Md3eReaderSeriesVolume(id: 'vol-03', title: '第 03 卷'),
    ];
